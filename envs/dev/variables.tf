# A subscription ID identifies the subscription but grants nothing on its own.
variable "subscription_id" {
  description = "Azure subscription that all resources are created in."
  type        = string
  default     = "fb41774d-87cb-41eb-997c-9dbe498cf34e"
}

variable "location" {
  description = "Azure region for all resources in this environment."
  type        = string
  default     = "uksouth"
}

variable "project" {
  description = "Project tag applied to every resource."
  type        = string
  default     = "azure-terraform-lab"
}

variable "env" {
  description = "Environment tag applied to every resource."
  type        = string
  default     = "dev"
}

variable "owner" {
  description = "Owner tag applied to every resource."
  type        = string
  default     = "moyo"
}
