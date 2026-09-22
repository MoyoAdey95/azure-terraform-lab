output "environment_id" {
  description = "ID of the Container Apps environment."
  value       = azurerm_container_app_environment.main.id
}

output "default_domain" {
  description = "Default domain for apps in the environment."
  value       = azurerm_container_app_environment.main.default_domain
}

output "static_ip_address" {
  description = "Public IP address the environment receives traffic on."
  value       = azurerm_container_app_environment.main.static_ip_address
}

output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace."
  value       = azurerm_log_analytics_workspace.main.id
}
