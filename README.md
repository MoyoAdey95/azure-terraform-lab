# azure-terraform-lab

A container platform on Azure. The third iteration of the same stack after [gcp-terraform-lab](https://github.com/MoyoAdey95/gcp-terraform-lab) and [aws-terraform-lab](https://github.com/MoyoAdey95/aws-terraform-lab). The application is deliberately trivial. The question the repo answers is whether the pattern holds on a third provider, and what Azure does differently from the other two.

Personal lab, not client or production work. Built, evidenced and destroyed by me in uksouth on a trial subscription. Nothing here runs now, so the docs and the captures in [docs/evidence](docs/evidence/) are the record of it working.

## Design

A small FastAPI service runs on Azure Container Apps behind the environment's own HTTPS ingress. Terraform builds everything from `envs/dev` using modules that mirror the layout of the GCP and AWS repos, so the three can be read side by side.

```
internet --HTTPS--> Container Apps ingress (http is redirected)
                      |
                      +--8080--> app, 0 to 2 replicas, scales to zero
                                  |
        ACR image and Key Vault secret <--+ (user-assigned managed identity)
                                  |
                      logs --> Log Analytics workspace

GitHub Actions --OIDC--> federated credential on a second identity
                         --> push to ACR, update the app, check the revision started
metric alert on 5xx responses --> action group --> email
```

No password, connection string or access key is used anywhere by the app or by CI. Storage account keys are switched off on the state account, and the registry's admin user is disabled. The exceptions, and what production would change, are in [docs/identity-decisions.md](docs/identity-decisions.md) and [docs/production-deltas.md](docs/production-deltas.md).

## What's in here

```
app/                 FastAPI service and Dockerfile, unchanged from the GCP and AWS repos
modules/
  network/           virtual network and the subnet delegated to Container Apps
  acr/               container registry
  identity/          the app's managed identity and its AcrPull role
  containerapps/     Log Analytics workspace, environment, and the app
  keyvault/          RBAC-mode vault, the secret, and the two roles on it
  monitoring/        action group and the 5xx alert
  ci/                CI identity, GitHub federated credential, and its two roles
envs/dev/            composition root, variables, outputs, backend
.github/workflows/   terraform checks on every push, deploy on app changes
docs/                bootstrap, decisions, comparison, production deltas, evidence
```

## Deploying it

Prerequisites. Terraform 1.11 or later, the Azure CLI signed in, Docker, and a budget on the subscription before anything is created.

The state storage account has to exist first, and it is the one thing not managed by Terraform. [docs/bootstrap.md](docs/bootstrap.md) has the CLI commands, including the data plane role that Owner does not give you.

Then, from `envs/dev`, with an email address for alerts set in the shell:

```bash
export TF_VAR_alert_email="you@example.com"
terraform init
terraform apply -target=module.acr
```

The app needs an image before it can start, so push one before the full apply.

```bash
az acr login --name <registry>
docker buildx build --platform linux/amd64 -t <registry>.azurecr.io/azure-lab-api:v1 --load app
docker push <registry>.azurecr.io/azure-lab-api:v1
terraform apply
curl "$(terraform output -raw app_url)/"
```

Container Apps runs amd64 only, so the `--platform` flag matters on an Apple Silicon Mac. After that, pushes to `main` that change `app/` build and deploy through GitHub Actions. The workflow needs three repository variables, `AZURE_CLIENT_ID`, `AZURE_TENANT_ID` and `AZURE_SUBSCRIPTION_ID`, and no secrets.

## Findings

The provider rejected the environment at apply time because `logs_destination` has to be set alongside the workspace ID. Validate and plan both passed first.

A deploy to an image tag that does not exist was accepted, reported as a successful apply, and left a revision at `ActivationFailed` while the previous revision kept serving. A green apply is not evidence that the new version is running, which is why the deploy workflow checks the revision's state.

The retail price list quotes $0.025 an hour for the environment's load balancer. The bill charged nothing for it against meters whose names end in Free.

A state write failed after a successful apply due to a dropped connection. The resources existed, the remote state did not know about them, and `terraform state push` of the local `errored.tfstate` recovered it without a fork.

`az storage account create` has no flag for defaulting the portal to Entra authorisation, so that setting goes through a generic `--set` with the ARM property name.

The captured output is in [docs/evidence](docs/evidence/). [docs/azure-vs-gcp-and-aws.md](docs/azure-vs-gcp-and-aws.md) compares all three builds and [docs/network-decisions.md](docs/network-decisions.md) covers the network and its cost.

## Teardown

```bash
terraform destroy
```

It took three runs. Twice the provider failed with `polling support for the Content-Type "" was not implemented`, once on the container app and once on the environment. Both deletes had actually succeeded in Azure, and the failure was azurerm 5.5 being unable to read the response it got back. Checking with `az containerapp list` before doing anything else is what confirmed that, and each following `terraform destroy` picked up from where the last one stopped.

The environment was the slow part. Its managed resource group, holding the load balancer and public IP, was already gone while Terraform was still waiting, and the delete ran 21 minutes before the polling error.

The key vault is gone rather than soft-deleted. The provider purges vaults on destroy by default, which is convenient in a lab, and worth knowing before you rely on soft delete to recover one.

Afterwards the subscription held only the state storage account, the cost export account, and a `NetworkWatcherRG` that Azure creates by itself when a virtual network first appears in a region. Nothing in this repo created it and it costs nothing. The state container keeps a 466 byte state file describing nothing.

## Cost

The whole build came to about $0.37 for 22 and 23 September, from the subscription's daily cost export. A full day with the app idle was $0.17, of which the registry was $0.10 and the public IP $0.08. Adding the final part day before teardown puts it near $0.45.

The load balancer was billed at zero, and the charged meters came in at roughly 60 per cent of list price. [docs/evidence/cost.txt](docs/evidence/cost.txt) has the breakdown and what I can and cannot tell from it.
