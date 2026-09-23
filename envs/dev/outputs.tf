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

output "app_identity_client_id" {
  description = "Client ID of the app's managed identity."
  value       = module.identity.client_id
}

output "containerapps_environment_id" {
  description = "ID of the Container Apps environment."
  value       = module.containerapps.environment_id
}

output "containerapps_default_domain" {
  description = "Default domain that app FQDNs in the environment sit under."
  value       = module.containerapps.default_domain
}

output "app_url" {
  description = "Public URL of the app."
  value       = "https://${module.containerapps.app_fqdn}"
}

output "key_vault_uri" {
  description = "URI of the key vault."
  value       = module.keyvault.vault_uri
}

output "ci_client_id" {
  description = "Client ID of the CI identity, used as AZURE_CLIENT_ID in the workflow."
  value       = module.ci.client_id
}

output "tenant_id" {
  description = "Tenant the CI identity authenticates against."
  value       = data.azurerm_client_config.current.tenant_id
}
