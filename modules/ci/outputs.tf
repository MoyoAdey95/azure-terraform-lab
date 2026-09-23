output "client_id" {
  description = "Client ID of the CI identity."
  value       = azurerm_user_assigned_identity.ci.client_id
}

output "principal_id" {
  description = "Object ID of the CI identity."
  value       = azurerm_user_assigned_identity.ci.principal_id
}
