# Log Analytics workspace and the Container Apps environment.
#
# The environment is the shared boundary the app runs in, the rough equivalent
# of an ECS cluster. It is joined to the lab's own subnet so the network is
# ours rather than one Azure creates out of sight.

# Retention is the 30 day minimum. The daily cap stops a noisy app from
# running up ingestion charges. Once it is reached, logs are dropped for the
# rest of the day.
resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-${var.name_prefix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
  daily_quota_gb      = 0.5
  tags                = var.tags
}

# logs_destination has to be set explicitly. With only the workspace ID the
# azurerm 5.5 provider rejects the environment during apply, after validate and plan
# have both passed.
#
# A workload profiles environment with only the Consumption profile. There is
# no dedicated compute to pay for by the hour, and apps scale to zero.
#
# Joining a subnet makes Azure create a second resource group holding a load
# balancer and public IP addresses for the environment. It is named here so
# it is predictable, and it is billed separately from the apps. The costs are
# in docs/network-decisions.md.
resource "azurerm_container_app_environment" "main" {
  name                               = "cae-${var.name_prefix}"
  resource_group_name                = var.resource_group_name
  location                           = var.location
  logs_destination                   = "log-analytics"
  log_analytics_workspace_id         = azurerm_log_analytics_workspace.main.id
  infrastructure_subnet_id           = var.subnet_id
  infrastructure_resource_group_name = "${var.resource_group_name}-infra"
  internal_load_balancer_enabled     = false

  workload_profile {
    name                  = "Consumption"
    workload_profile_type = "Consumption"
  }

  tags = var.tags
}
