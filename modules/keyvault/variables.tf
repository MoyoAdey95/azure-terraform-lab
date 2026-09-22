variable "name" {
  description = "Globally unique vault name, 3 to 24 letters, digits and hyphens."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group the vault is created in."
  type        = string
}

variable "location" {
  description = "Azure region for the vault."
  type        = string
}

variable "tenant_id" {
  description = "Entra tenant that authenticates requests to the vault."
  type        = string
}

variable "admin_principal_id" {
  description = "Object ID of the principal that manages secrets, normally whoever runs Terraform."
  type        = string
}

variable "app_principal_id" {
  description = "Object ID of the app's managed identity."
  type        = string
}

variable "tags" {
  description = "Tags applied to the vault."
  type        = map(string)
}
