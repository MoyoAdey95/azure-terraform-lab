# Production deltas

Everything here is chosen for a lab that gets built, evidenced and destroyed. This page lists what would change if the same stack had to run in production, and why each decision was made.

## Network exposure

The storage account, the registry, and the key vault all accept traffic from any network. Locking them down means private endpoints which bill by the hour, and would need the lab up permanently to be worth having. Production would put private endpoints on all three and turn public network access off.

The Container Apps subnet has no network security group. Traffic reaches the app through the environment's ingress, but a production subnet would have a network security group as a second control.

The subnet was created with `default_outbound_access_enabled` true, the provider's default. The environment routes its own outbound traffic, so the setting changes nothing here. Production would turn it off so nothing placed in the network later picks up an outbound address implicitly.

## Registry

ACR Basic has no retention policy, no private endpoint, and no way to disable the export policy. It also cannot make tags immutable, so the convention in this repo is that a tag is written once and never moved. CI pushes a tag per commit, which keeps that honest. Nothing deletes old images. A production registry on Premium would enforce tag immutability and expire untagged manifests automatically.

There is no image scanning. The scanning Azure offers comes through Microsoft Defender for Containers, which is charged monthly. The Dockerfile upgrades base packages at build time to narrow the gap. That is not a substitute for scan results.

## Secrets

The demo secret's value comes from a Terraform variable, so it also sits in the state file in plain text. The state is in a storage account with shared key access disabled, so reading it needs an Entra identity with a data plane role. A real secret would be created outside Terraform with only its name managed here.

Purge protection is off on the key vault, so a teardown can purge the vault and free the name immediately. Production would turn purge protection on and accept the wait.

## Logs and alerting

The Log Analytics workspace keeps the minimum 30 days, and has a 0.5 GB daily cap. Once the cap is hit the workspace stops ingesting for the rest of the day, which protects the credit and loses data. Production would size retention to whatever the audit requirement is and set the cap well above normal volume.

The environment sends logs to the workspace using the workspace's shared key, so `local_authentication_enabled` has to stay on. That is the one key-based path in the lab and there is no way to remove it while keeping logs in Log Analytics.

There is one alert which is on 5xx responses, and it has never fired. Production would add restart and latency alerts, an action group with more than one receiver, and a routine that tests the alerts rather than assuming they work.

## Availability

The environment is not zone redundant and the app scales to zero. The first request after an idle period waits about 16 seconds. A production app with real users would keep at least one replica running and enable zone redundancy on the environment.

Revision mode is Single, so a deploy replaces the running revision once it is healthy. Production would use multiple revisions with a traffic split, so a new version can take a small share of traffic before it takes all of it.

## Who runs Terraform

Terraform runs locally as a human account holding Owner at subscription scope. Production would run it in CI as its own identity, with a role scoped to what it manages. The human role would stop short of managing role assignments.

The CI workflows deploy on a push to main with no approval step and no environment protection rules. There is no plan on pull requests and no scheduled drift detection. All three are straightforward to add and were left out because this repo has one environment and one person working on it.

## Known warnings not addressed

`azure/login@v2` runs on Node 20, which GitHub has deprecated, so every deploy run carries that annotation. It is the action's own code rather than anything in this repo. The fix is a newer version of the action when Microsoft publishes one.
