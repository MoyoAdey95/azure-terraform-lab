output "id" {
  description = "ID of the registry, used as the scope for role assignments."
  value       = azurerm_container_registry.main.id
}

output "login_server" {
  description = "Login server of the registry."
  value       = azurerm_container_registry.main.login_server
}
