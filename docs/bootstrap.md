# Bootstrap: the Terraform state storage account

Terraform keeps its state in Azure Blob Storage, and the storage account that holds it has to exist before `terraform init` can run. It sits outside Terraform for that reason. This page records how it was built and gives the CLI commands to build the same thing from scratch.

## What exists

Azure needs three things. A resource group `rg-azure-lab-tfstate`, a storage account `moyoazlabtfstate` inside it, and a blob container `tfstate` inside that. State for this environment lives at `azure-terraform-lab/dev/terraform.tfstate` in the container. Everything is in uksouth.

The state has its own resource group so that nothing done to the lab's resource group can reach it. Deleting a resource group deletes everything in it, and the state is the one thing that should survive a teardown.

I built the storage account in the Azure portal. Even the portal goes through Azure Resource Manager, so the build left a deployment record in the resource group with the template it generated. The resource group tags, the role assignment and the container were added afterwards with the CLI, because the portal wizard only tags the storage account and stops at creating it.

The settings below were read back after the build with `az storage account show`, `az storage account blob-service-properties show`, `az group show` and `az role assignment list`.

| Setting | Value |
|---|---|
| Region | uksouth |
| Kind and SKU | StorageV2, Standard_LRS, Hot tier |
| Storage account key access | Disabled |
| Anonymous blob access | Disabled |
| Default to Entra authorisation in the portal | Enabled |
| Secure transfer | HTTPS only, minimum TLS 1.2 |
| Cross-tenant replication | Disabled |
| Copy scope | Same Entra tenant only |
| Hierarchical namespace | Off |
| Blob versioning | Enabled |
| Blob and container soft delete | 7 days each |
| Encryption | Microsoft-managed keys |
| Public network access | Enabled from all networks |
| Defender for Storage | Off |
| Tags, on the account and the resource group | project=azure-terraform-lab, env=dev, owner=moyo, managed-by=console-bootstrap |

Versioning matters most. If a state file is corrupted, the previous version is still there.

Turning off key access is the decision that shapes the rest. Every storage account comes with two account keys that give full access to its data, which is the Azure version of a long-lived access key. With them disabled, the only way in is an Entra identity with a data plane role. The backend in `envs/dev/versions.tf` sets `use_azuread_auth = true` and authenticates with the `az login` session.

That has a consequence that is easy to miss. Owner on the subscription covers the management plane, creating and configuring the account, but it does not let you read or write blobs. I needed Storage Blob Data Contributor on the storage account as well before the container could be created.

## Why there is no lock table

The azurerm backend locks state by taking a lease on the state blob. A lease is a native Blob Storage feature that lets only one client write the blob until the lease is released, so no separate locking resource is needed. A run that dies holding a lease can be cleared with `terraform force-unlock`.

## Building it with the CLI

These commands produce the same setup. They assume `az login` has been run against the right subscription. Storage account names are global and must be 3 to 24 lowercase letters and digits, so change `ACCOUNT` to something unused and check it first with `az storage account check-name`.

```bash
export RG=rg-azure-lab-tfstate
export ACCOUNT=moyoazlabtfstate
export LOCATION=uksouth

az group create --name "$RG" --location "$LOCATION" \
  --tags project=azure-terraform-lab env=dev owner=moyo managed-by=cli-bootstrap

az storage account create --name "$ACCOUNT" --resource-group "$RG" \
  --location "$LOCATION" --sku Standard_LRS --kind StorageV2 --access-tier Hot \
  --https-only true --min-tls-version TLS1_2 \
  --allow-blob-public-access false --allow-shared-key-access false \
  --allow-cross-tenant-replication false \
  --allowed-copy-scope AAD --public-network-access Enabled \
  --tags project=azure-terraform-lab env=dev owner=moyo managed-by=cli-bootstrap

az storage account update --name "$ACCOUNT" --resource-group "$RG" \
  --set defaultToOAuthAuthentication=true

az storage account blob-service-properties update --account-name "$ACCOUNT" --resource-group "$RG" \
  --enable-versioning true \
  --enable-delete-retention true --delete-retention-days 7 \
  --enable-container-delete-retention true --container-delete-retention-days 7

az role assignment create --assignee "$(az ad signed-in-user show --query id -o tsv)" \
  --role "Storage Blob Data Contributor" \
  --scope "$(az storage account show --name "$ACCOUNT" --resource-group "$RG" --query id -o tsv)"

az storage container create --name tfstate --account-name "$ACCOUNT" --auth-mode login
```

Azure CLI 2.90.0 has no flag on `create` or `update` for defaulting the portal to Entra authorisation, so that one setting goes through the generic `--set` with its ARM property name.

The tags are written out in full on each command. An earlier version kept them in a shell variable, and zsh, the default shell on macOS, passed the whole string as a single tag called `project`. Bash would have split it into four.

The role assignment can take a few minutes to take effect. If the container create fails with an authorisation error straight after it, wait and run it again.

Resources built this way get `managed-by=cli-bootstrap`. The tag records how the resource came to exist, and none of this was built by Terraform.

Once the container exists, `terraform init` from `envs/dev/` connects to it.
