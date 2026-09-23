output "id" {
  description = "ID of the key vault."
  value       = azurerm_key_vault.main.id
}

output "vault_uri" {
  description = "URI of the key vault."
  value       = azurerm_key_vault.main.vault_uri
}

# Versionless, so the app picks up a new value without the ID changing.
output "app_message_secret_id" {
  description = "Versionless ID of the app message secret."
  value       = azurerm_key_vault_secret.app_message.versionless_id
}
