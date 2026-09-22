# Container registry for the app image.
#
# Basic is the cheapest SKU. It has no retention policy, no private endpoint
# and no image scanning, and ACR has no registry-wide setting to make tags
# immutable. Images are pushed under unique tags instead, and the gaps are
# listed in docs/production-deltas.md.

resource "azurerm_container_registry" "main" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Basic"

  # The admin user is a single username and password with full access to the
  # registry. Pulls go through a managed identity instead.
  admin_enabled = false

  tags = var.tags
}
