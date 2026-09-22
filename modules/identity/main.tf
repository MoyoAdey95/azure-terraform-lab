# Managed identity the container app runs as.
#
# It is user-assigned rather than system-assigned. A system-assigned identity
# only exists once the app does, so it cannot be granted AcrPull before the
# app's first image pull, and the first revision fails. A user-assigned
# identity has its own lifecycle, so its roles are in place before the app is
# created.

resource "azurerm_user_assigned_identity" "app" {
  name                = "id-${var.name_prefix}-app"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

# Pull only, scoped to the one registry.
resource "azurerm_role_assignment" "acr_pull" {
  scope                = var.acr_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.app.principal_id
  principal_type       = "ServicePrincipal"
}
