# Evidence

Command output captured from the running lab, mostly on 23 September 2026.
Each file names the command above its output. Nothing here is edited except
to remove blank lines.

| File | What it shows |
|---|---|
| `state-backend.txt` | The state blob in blob storage, and the storage account with shared key access disabled |
| `network.txt` | The subnet delegation, and the load balancer and public IP that the environment created in its own resource group |
| `registry.txt` | Registry settings with the admin user disabled, and the image manifests |
| `identity.txt` | Both managed identities with their roles, and the federated credential trusting GitHub |
| `app-live.txt` | The app answering over HTTPS, the redirect from plain HTTP, and the revision list |
| `secret.txt` | The app's secret as a Key Vault URL and an identity, with no value, and the environment variable that reads it |
| `scale-to-zero.txt` | The app at zero replicas after five minutes without traffic |
| `failed-deploy.txt` | A deploy to a tag that does not exist, and what the app did about it |
| `alerting.txt` | The action group and the 5xx alert rule |
| `ci-run.txt` | Deploy runs, including the step that checks the new revision is running |
| `cost.txt` | What the lab actually cost |

The alert in `alerting.txt` was never fired. The one attempt to fire it, in
`failed-deploy.txt`, produced no 5xx responses because the app stayed up.
