# Virtual network for the lab with a single subnet for the Container Apps
# environment.
#
# Azure subnets span every zone in the region, so one subnet is enough. There
# is no route table or gateway to build either. Outbound traffic from the
# environment leaves through a load balancer and public IP that Container Apps
# creates and manages itself.

resource "azurerm_virtual_network" "main" {
  name                = "vnet-${var.name_prefix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = [var.vnet_cidr]
  tags                = var.tags
}

# The delegation hands control of the subnet to Container Apps. Nothing else
# can be placed in it once the environment is using it.
resource "azurerm_subnet" "apps" {
  name                 = "snet-${var.name_prefix}-apps"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.apps_subnet_cidr]

  delegation {
    name = "container-apps"

    service_delegation {
      name    = "Microsoft.App/environments"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}
