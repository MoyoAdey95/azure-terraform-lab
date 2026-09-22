output "resource_group_name" {
  description = "Name of the lab resource group."
  value       = azurerm_resource_group.lab.name
}

output "vnet_id" {
  description = "ID of the virtual network."
  value       = module.network.vnet_id
}

output "apps_subnet_id" {
  description = "ID of the subnet delegated to Container Apps."
  value       = module.network.apps_subnet_id
}

output "acr_login_server" {
  description = "Login server of the container registry, used as the image prefix."
  value       = module.acr.login_server
}
