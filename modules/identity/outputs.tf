output "id" {
  description = "Resource ID of the app identity, attached to the container app."
  value       = azurerm_user_assigned_identity.app.id
}

output "client_id" {
  description = "Client ID of the app identity."
  value       = azurerm_user_assigned_identity.app.client_id
}

output "principal_id" {
  description = "Object ID of the app identity, used in role assignments."
  value       = azurerm_user_assigned_identity.app.principal_id
}
