output "vnet_id" {
  description = "ID of the virtual network."
  value       = azurerm_virtual_network.main.id
}

output "apps_subnet_id" {
  description = "ID of the subnet delegated to Container Apps."
  value       = azurerm_subnet.apps.id
}
