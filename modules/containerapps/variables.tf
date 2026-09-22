variable "name_prefix" {
  description = "Prefix for resource names."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group the environment and workspace are created in."
  type        = string
}

variable "location" {
  description = "Azure region for the environment."
  type        = string
}

variable "subnet_id" {
  description = "ID of the subnet delegated to Microsoft.App/environments."
  type        = string
}

variable "tags" {
  description = "Tags applied to every taggable resource in the module."
  type        = map(string)
}
