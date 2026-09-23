# Azure compared with GCP and AWS

This is the same stack for the third time. A container behind a public HTTPS endpoint, a secret injected at runtime, an alert when something breaks, and a deploy from CI with no stored credentials. gcp-terraform-lab did it on Cloud Run, aws-terraform-lab on ECS Fargate, and this repo on Container Apps. What follows is what actually differed while building all three.

## Networking

Cloud Run needed no network at all. Google's frontend took the request and the VPC existed for other reasons. AWS needed five resources before anything could serve traffic, an internet gateway, a route table, subnets in two availability zones and a load balancer with a target group and listener.

Azure sits between the two. One virtual network and one subnet delegated to Container Apps, and no route table, gateway or second subnet, because Azure subnets already span every zone in the region. The environment then builds its own load balancer and public IP in a resource group it manages, which is closer to the Cloud Run experience except that the bill for it is visible. The delegation is the genuinely new idea. The subnet is handed over to the service, and nothing else can be put in it.

The cost shape is different in each. Cloud Run charged nothing for the endpoint. The ALB billed hourly from the moment it existed. The Container Apps environment bills for its public IP whether or not there is traffic, which measured at $0.005 an hour. Its load balancer showed up on the bill against free meters at zero, though the retail price list quotes $0.025 an hour for a standard load balancer.

## The resource group

This is the one Azure concept the other two have no real equivalent for. Every resource belongs to exactly one resource group, and deleting the group deletes everything in it. That makes it a lifecycle boundary rather than a label, which is why the Terraform state account here lives in a separate group from the lab. On GCP a project is the nearest thing but is much heavier, and on AWS nothing groups resources for deletion at all, which is why teardown there means destroying resources one dependency at a time.

The environment leaned on the same idea. Joining it to a subnet made Azure create a second resource group holding its load balancer and public IP, marked as managed by the environment and tagged with the lab's tags plus one of its own.

## Where Azure asked for more

**Provider registration.** Each Azure resource provider has to be registered on the subscription before it can be used. That is the analogue of enabling APIs on GCP, which gcp-terraform-lab also had to do, and AWS has nothing like it. `Microsoft.ManagedIdentity` and `Microsoft.Insights` both had to be registered mid-build, and an unregistered provider produces an error that does not obviously say so.

**Tags on every resource.** The AWS provider has `default_tags` and the Google provider has `default_labels`, both applied from the provider block. azurerm has neither, so every resource passes tags in explicitly through a local. Forgetting one fails silently.

**Two identity planes.** Owner at subscription scope does not let you read a blob or a secret. Data plane access is a separate role. Storage Blob Data Contributor to write state, and Key Vault Secrets Officer to write the secret. The split is real on AWS and GCP too, but Azure is the one where an account that can create and configure a resource still cannot read what is inside it.

**Slower control plane.** A resource group took 35 seconds, while the Key Vault, the metric alert, and the Container Apps environment all took roughly 3 minutes each. Role assignments took 35 to 40 seconds each and are not usable the instant they exist. This is why the vault, its roles, and the secret were split across two applies here.

## Where Azure asked for less

**Scale to zero with a public endpoint.** Container Apps scales the app to zero after five minutes of no traffic and still keeps a working HTTPS URL, with a measured 16 second cold start. Cloud Run does this too, though gcp-terraform-lab managed to pay for an always-warm instance until `cpu_idle` was fixed. Fargate has no equivalent. The task runs and bills until something stops it.

**Secrets.** The container app references a Key Vault secret by a versionless URL and fetches it with its own identity. ECS does the same with a Secrets Manager ARN. The Azure version rotates without redeploying, since the versionless URL keeps pointing at the current value.

**No architecture decision.** ECS Fargate offered Graviton, so aws-terraform-lab runs ARM64 natively built on an Apple Silicon Mac. Container Apps supports amd64 only, so the image is cross-built locally and built natively in CI. Less choice, but also less to get wrong.

## Deploying from CI

All three end in the same place. GitHub Actions authenticates with a short-lived token and no stored key. gcp-terraform-lab only validated Terraform and never authenticated, with federation named in its docs as the production answer. aws-terraform-lab deploys through a role's trust policy. This repo uses a federated credential on a user-assigned managed identity, so there is no app registration and no service principal password.

Both this repo and the AWS one hit GitHub's immutable subject format, where the `sub` claim carries numeric owner and repository IDs rather than names. Having been caught by it once, the value here was read from the GitHub API before the credential was written, and the first run passed.

## What a deploy means

The most useful difference came from breaking things on purpose. Deploying a tag that does not exist was accepted by Azure, reported as a successful apply, and produced a revision that ended at `ActivationFailed`, while the previous revision carried on serving. ECS handles the same case with a deployment circuit breaker that rolls back. Both keep the app up. The Azure version needs the deploy pipeline to check the new revision's running state, because the API's success is about the configuration rather than the container.

## Monitoring

The AWS alarm watched `HealthyHostCount` and fired nine minutes late because a load balancer with no targets stops publishing the metric entirely. An alert on replicas would misfire every time the app correctly scaled to zero, so the alert here watches requests returning 5xx, which only happens when a user is actually affected. It has not fired, and the one attempt to make it fire produced no errors because the app stayed up.

## Conclusion

For a small containerised service with uneven traffic, Container Apps and Cloud Run are both easier to run than Fargate, and both bill nothing while idle. Azure's resource group makes cleanup safer than either. Fargate gives the most control over the request path and the only ARM option of the three. The thing that transfers between all of them is really just the shape. One network decision, one identity per workload, secrets by reference, and a deploy that proves the new version is running rather than assuming it.
