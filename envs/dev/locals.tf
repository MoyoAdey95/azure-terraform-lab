# The azurerm provider has no equivalent of default_tags on the AWS provider,
# so every resource passes these in explicitly.
locals {
  common_tags = {
    project      = var.project
    env          = var.env
    owner        = var.owner
    "managed-by" = "terraform"
  }
}
