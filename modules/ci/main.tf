# Identity GitHub Actions uses to deploy.
#
# There is no client secret and no service principal password. GitHub signs a
# token for the workflow run, Azure checks the issuer, audience and subject,
# and hands back an access token for this identity.

resource "azurerm_user_assigned_identity" "ci" {
  name                = "id-${var.name_prefix}-ci"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

# The subject has to match the sub claim GitHub puts in the token exactly.
# This repository issues an immutable subject, with numeric owner and
# repository IDs rather than names, so the value is read from the GitHub API
# rather than assembled by hand.
# azurerm 5 replaced parent_id and resource_group_name on this resource with
# a single user_assigned_identity_id.
resource "azurerm_federated_identity_credential" "github_main" {
  name                      = "github-main"
  user_assigned_identity_id = azurerm_user_assigned_identity.ci.id
  audience                  = ["api://AzureADTokenExchange"]
  issuer                    = "https://token.actions.githubusercontent.com"
  subject                   = var.github_subject
}

# Push and pull on the one registry.
resource "azurerm_role_assignment" "ci_acr_push" {
  scope                = var.acr_id
  role_definition_name = "AcrPush"
  principal_id         = azurerm_user_assigned_identity.ci.principal_id
  principal_type       = "ServicePrincipal"
}

# Scoped to the single app, not the resource group, so CI cannot touch the
# environment, the vault, the registry settings or the network.
resource "azurerm_role_assignment" "ci_app_contributor" {
  scope                = var.app_id
  role_definition_name = "Container Apps Contributor"
  principal_id         = azurerm_user_assigned_identity.ci.principal_id
  principal_type       = "ServicePrincipal"
}
