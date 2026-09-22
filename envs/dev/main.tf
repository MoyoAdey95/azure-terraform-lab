# Composition root for the dev environment. Modules do the work and this file
# wires them together.

# Everything the lab creates goes in this one resource group, so deleting it
# removes the lab. The state storage account is in a separate group for that
# reason.
resource "azurerm_resource_group" "lab" {
  name     = "rg-${var.name_prefix}"
  location = var.location
  tags     = local.common_tags
}

module "network" {
  source = "../../modules/network"

  name_prefix         = var.name_prefix
  resource_group_name = azurerm_resource_group.lab.name
  location            = azurerm_resource_group.lab.location
  vnet_cidr           = var.vnet_cidr
  apps_subnet_cidr    = var.apps_subnet_cidr
  tags                = local.common_tags
}

module "acr" {
  source = "../../modules/acr"

  name                = var.acr_name
  resource_group_name = azurerm_resource_group.lab.name
  location            = azurerm_resource_group.lab.location
  tags                = local.common_tags
}

module "identity" {
  source = "../../modules/identity"

  name_prefix         = var.name_prefix
  resource_group_name = azurerm_resource_group.lab.name
  location            = azurerm_resource_group.lab.location
  acr_id              = module.acr.id
  tags                = local.common_tags
}

module "containerapps" {
  source = "../../modules/containerapps"

  name_prefix         = var.name_prefix
  resource_group_name = azurerm_resource_group.lab.name
  location            = azurerm_resource_group.lab.location
  subnet_id           = module.network.apps_subnet_id
  identity_id         = module.identity.id
  acr_login_server    = module.acr.login_server
  image_tag           = var.image_tag
  app_port            = var.app_port
  tags                = local.common_tags
}
