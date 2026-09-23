# Key vault for the app's secret.
#
# Access is by Azure role assignments rather than the older vault access
# policies, so it is granted and audited the same way as every other
# permission in the lab.
#
# Soft delete cannot be turned off. The retention is the 7 day minimum, and
# purge protection is off so a teardown can purge the vault and free the
# name. Production would turn purge protection on.

resource "azurerm_key_vault" "main" {
  name                       = var.name
  resource_group_name        = var.resource_group_name
  location                   = var.location
  tenant_id                  = var.tenant_id
  sku_name                   = "standard"
  rbac_authorization_enabled = true
  soft_delete_retention_days = 7
  purge_protection_enabled   = false
  tags                       = var.tags
}

# Lets whoever runs Terraform create and update secrets.
resource "azurerm_role_assignment" "admin_secrets_officer" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = var.admin_principal_id
}

# Lets the app read secret values and nothing else. The vault holds only the
# app's secret, so vault scope is no wider than the secret itself.
resource "azurerm_role_assignment" "app_secrets_user" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = var.app_principal_id
  principal_type       = "ServicePrincipal"
}

# The value comes from a Terraform variable, so it is also stored in the state
# file in plain text. The state is in a storage account with key access off
# and only Entra access, but in production the value would be set outside
# Terraform and only the secret's name managed here.
resource "azurerm_key_vault_secret" "app_message" {
  name         = "app-message"
  value        = var.app_message
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [azurerm_role_assignment.admin_secrets_officer]
}
