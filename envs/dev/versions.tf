terraform {
  required_version = ">= 1.11"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.5"
    }
  }

  # Storage account key access is disabled, so the backend authenticates
  # through Entra ID using the az login session. Locking uses a blob lease.
  backend "azurerm" {
    storage_account_name = "moyoazlabtfstate"
    container_name       = "tfstate"
    key                  = "azure-terraform-lab/dev/terraform.tfstate"
    use_azuread_auth     = true
  }
}
