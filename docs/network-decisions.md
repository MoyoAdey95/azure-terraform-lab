# Network decisions

The network is one virtual network, `vnet-azure-lab` on 10.30.0.0/16, with one subnet, `snet-azure-lab-apps` on 10.30.1.0/24, delegated to `Microsoft.App/environments`. The Container Apps environment is joined to that subnet and has external ingress. This page explains the choices and what they cost.

## One subnet

Azure subnets are regional and span every availability zone, so there is no need for one subnet per zone. There is no route table or internet gateway to build either. The environment handles its own inbound and outbound traffic.

The delegation hands the subnet to Container Apps. Once the environment is using it, nothing else can be placed in it.

Container Apps needs at least a /27. Of that it reserves 12 addresses for itself, on top of the 5 Azure reserves in every subnet, and the Consumption profile takes one more address for every 10 replicas. A /27 would be enough for this app, but a /24 costs nothing extra and leaves room to grow. A validation on the variable stops anything smaller than /27 reaching a plan.

Some ranges cannot be used for the subnet at all because Container Apps and the platform underneath it reserve them, including 169.254.0.0/16, 172.30.0.0/16, 172.31.0.0/16, 192.0.2.0/24 and several blocks in 100.100.0.0/16. 10.30.0.0/16 avoids all of them.

## What the environment creates

Joining the environment to our own subnet makes Azure create a second resource group for the environment's infrastructure. By default it gets a generated name starting `ME_`. The module sets `infrastructure_resource_group_name` so it is called `rg-azure-lab-infra` instead, which makes it easy to find and puts it in the code.

After apply that group held two resources, a standard load balancer called `capp-svc-lb` and a standard public IP called `capp-svc-lb-ip`. The environment's static IP is that address, and it carries both inbound and outbound traffic.

The group is marked as managed by the environment, and Azure copied the four lab tags onto it along with a tag of its own, `aca-managed-env-id`. Nothing in Terraform manages the group directly. It is created and removed with the environment.

## What it costs

Prices for uksouth from the Azure retail prices API on 17 September 2026. A month is taken as 730 hours.

| Item | Retail price | Per month |
|---|---|---|
| Standard load balancer, first 5 rules | $0.025 per hour, plus $0.005 per GB processed | $18.25 before data |
| Standard static public IPv4 | $0.005 per hour | $3.65 |

The load balancer price is listed under the region `Global` rather than uksouth, so a query filtered on uksouth returns nothing for it.

The bill did not match that. In the first day of usage data the load balancer appears against meters named `Standard Included LB Rules and Outbound Rules - Free` and `Standard Data Processed - Free`, both at zero, while the public IP was charged normally. So the environment's networking cost this subscription $0.005 an hour, about $3.65 a month, not the $0.030 an hour the price list implied. The charged figures are in `docs/evidence/cost.txt`.

Whether that is a free tier, a trial subscription behaviour or how Azure treats a load balancer it manages on your behalf, I cannot tell from the usage data alone. The retail price is what the price list says, and the meter is what was actually billed. Worth knowing that the two can differ, and worth checking the meters rather than the price list before promising a figure to anyone.

The app itself runs on the Consumption profile and scales to zero, so with no traffic it costs nothing, and the free monthly allowance of vCPU-seconds, GiB-seconds and requests covers a lab this size when it does run.

Container Apps can also run in a network Azure provides, with no subnet of our own, and Microsoft documents the load balancer and public IP as a consequence of bringing your own network. The lab uses its own network so that the address space, the subnet and the delegation are all visible in the code.

## Ingress

The app's ingress is external and HTTPS only. Azure provides the certificate for the default domain. A plain HTTP request gets a 301 redirect to the HTTPS address, which is `allow_insecure_connections` left at false.

With `min_replicas` at 0 the first request after the app has scaled down waits for a replica to start. The first request after the app was created took 15.8 seconds end to end. Once a replica is running, requests return straight away.

## What I would do differently in production

The subnet has no network security group. Traffic reaches the app through the environment's ingress, but a production subnet would have a network security group as a second control.

The subnet was created with `default_outbound_access_enabled` true, the provider's default. The environment sends outbound traffic through its own load balancer, so the setting does not affect the app. Production would turn it off, so nothing else placed in the network gets an outbound address implicitly.

A production app with steady traffic would keep at least one replica running rather than scaling to zero, because a 15 second first response is fine for a lab and not for users.

## Checking it

`az network vnet subnet show` returned the address prefix and the `Microsoft.App/environments` delegation. `az resource list` on `rg-azure-lab-infra` showed exactly one load balancer and one public IP. `az group show` on the same group showed the `managedBy` link to the environment and the copied tags. A timed `curl` against the app URL gave the cold start, and a `curl` over plain HTTP returned the 301.
