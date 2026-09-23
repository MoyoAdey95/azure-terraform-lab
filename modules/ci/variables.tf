variable "name_prefix" {
  description = "Prefix for CI resource names."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group the CI identity is created in."
  type        = string
}

variable "location" {
  description = "Azure region for the CI identity."
  type        = string
}

variable "acr_id" {
  description = "ID of the registry CI pushes images to."
  type        = string
}

variable "app_id" {
  description = "ID of the container app CI updates."
  type        = string
}

variable "github_subject" {
  description = "Full sub claim the workflow's token carries, including the ref."
  type        = string
}

variable "tags" {
  description = "Tags applied to the CI identity."
  type        = map(string)
}
