provider "azurerm" {
  subscription_id = var.subscription_id

  # Key access is off on storage accounts in this lab, so any storage data
  # plane call the provider makes has to use Entra ID as well.
  storage_use_azuread = true

  features {}
}
