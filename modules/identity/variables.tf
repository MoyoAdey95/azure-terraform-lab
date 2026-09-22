variable "name_prefix" {
  description = "Prefix for identity names."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group the identity is created in."
  type        = string
}

variable "location" {
  description = "Azure region for the identity."
  type        = string
}

variable "acr_id" {
  description = "ID of the container registry the app pulls from."
  type        = string
}

variable "tags" {
  description = "Tags applied to the identity."
  type        = map(string)
}
