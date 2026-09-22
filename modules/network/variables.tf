variable "name_prefix" {
  description = "Prefix for network resource names."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group the network is created in."
  type        = string
}

variable "location" {
  description = "Azure region for the network."
  type        = string
}

variable "vnet_cidr" {
  description = "Address space for the virtual network."
  type        = string
}

variable "apps_subnet_cidr" {
  description = "CIDR block for the Container Apps subnet."
  type        = string

  validation {
    condition     = tonumber(split("/", var.apps_subnet_cidr)[1]) <= 27
    error_message = "Container Apps needs a subnet of /27 or larger."
  }
}

# azurerm has no provider-level default tags, so they are passed in.
variable "tags" {
  description = "Tags applied to every taggable resource in the module."
  type        = map(string)
}
