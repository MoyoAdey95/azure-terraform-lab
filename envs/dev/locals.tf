# The aws and google providers both apply a set of tags or labels to every
# resource from the provider block, through default_tags and default_labels.
# azurerm has no equivalent, so every resource passes these in explicitly.
locals {
  common_tags = {
    project      = var.project
    env          = var.env
    owner        = var.owner
    "managed-by" = "terraform"
  }
}
