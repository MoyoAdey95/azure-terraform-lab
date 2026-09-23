# Identity decisions

Nothing in this lab authenticates with a password, a connection string or an access key, with two exceptions that are listed at the end. This page sets out what holds which permission and why.

## What authenticates to what

| Caller | Identity | Permission | Scope |
|---|---|---|---|
| Terraform, run locally | My Entra user, from `az login` | Owner, inherited at the subscription | Subscription |
| Terraform, writing state | The same user | Storage Blob Data Contributor | The state storage account |
| Terraform, writing the secret | The same user | Key Vault Secrets Officer | The vault |
| The app, pulling its image | `id-azure-lab-app`, a user-assigned managed identity | AcrPull | The one registry |
| The app, reading its secret | The same identity | Key Vault Secrets User | The vault |

The app's identity holds two roles only. It cannot write to the registry, write to the vault, or read anything outside the vault.

## User-assigned rather than system-assigned

A system-assigned identity is created with the resource it belongs to and dies with it. That sounds simpler, and for the app it does not work. The identity would not exist until the app was created, so it could not be given AcrPull beforehand, and the first revision would try to pull an image it had no permission to read.

A user-assigned identity is a resource in its own right. It is created first, given its roles, and then attached to the app. Terraform's dependency graph handles the ordering without anything explicit.

## Role assignments and timing

Role assignments are not instant. In this lab they took between 35 and 40 seconds to create, and a newly created assignment can take longer than that to be usable.

That is why the vault and its role assignments were applied in one commit and the secret in the next. If Terraform had created the Secrets Officer role and then written the secret in the same run, the write could have been refused before the role became active. Splitting the work across two applies avoids the problem without a sleep or a retry loop.

`principal_type = "ServicePrincipal"` is set on the assignments for the managed identity. It tells Azure what kind of principal it is dealing with instead of making it look the principal up, which can fail for an identity created moments earlier.

## Key Vault in RBAC mode

The vault uses Azure role assignments rather than vault access policies. Access policies are a separate permission system that only applies to Key Vault, so a vault using them has to be audited on its own. With RBAC the vault's permissions show up in the same role assignment queries as everything else.

## Where keys still exist

The Container Apps environment sends its logs to Log Analytics with the workspace's shared key. `local_authentication_enabled` is true on the workspace because turning it off would stop the logs. It is the one key-based path in the lab.

The state file holds the value of the demo secret in plain text, because the value comes from a Terraform variable. The state is in a storage account with shared key access disabled, so reading it requires an Entra identity with a data plane role. A real secret would be created outside Terraform, with only its name managed here.

## Lab pragmatism

My own account holds Owner at subscription scope. That is fine for a personal lab where one person builds everything, and it is not how a production subscription should be run. There, Terraform would authenticate as its own service principal with a scoped role, and a human would have a role that stops short of managing role assignments.

The storage account and the registry both allow access from any network. Restricting them needs private endpoints.

## Checking it

`az role assignment list --assignee` against the app's principal ID returned exactly two rows, AcrPull on the registry and Key Vault Secrets User on the vault. `az role assignment list --scope` against the vault showed the two vault roles with their principal types. `az containerapp show` showed the app's secret as a Key Vault URL and an identity with no value. The image pull and the secret read both worked on the first attempt with no password configured anywhere.
