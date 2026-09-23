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

variable "name_prefix" {
  description = "Prefix for resource names."
  type        = string
  default     = "azure-lab"
}

variable "vnet_cidr" {
  description = "Address space for the virtual network. Kept clear of 10.10.0.0/24 in gcp-terraform-lab and 10.20.0.0/16 in aws-terraform-lab."
  type        = string
  default     = "10.30.0.0/16"
}

# Container Apps needs at least a /27. A /24 costs nothing extra and leaves
# room for the addresses the environment takes as it scales.
variable "apps_subnet_cidr" {
  description = "CIDR block for the subnet delegated to the Container Apps environment."
  type        = string
  default     = "10.30.1.0/24"
}

# Registry names are global and letters and digits only. Checked as free with
# az acr check-name before the first apply.
variable "acr_name" {
  description = "Name of the container registry."
  type        = string
  default     = "moyoazlabacr"
}

# Tags are treated as immutable by convention, since ACR cannot enforce it.
variable "image_tag" {
  description = "Tag of the app image in the registry to run."
  type        = string
  default     = "v1"
}

# Matches the PORT the container listens on.
variable "app_port" {
  description = "Port the application container listens on."
  type        = number
  default     = 8080
}

# Vault names are global. A deleted vault keeps its name reserved until the
# soft delete period ends. Checked as free on 22 Sep 2026.
variable "key_vault_name" {
  description = "Name of the key vault."
  type        = string
  default     = "kv-azure-lab-moyo"
}

variable "app_message" {
  description = "Value stored in the demo secret and returned by the app."
  type        = string
  sensitive   = true
  default     = "hello from key vault"
}

# No default, so no address is committed to a public repo. Set it in the shell
# with TF_VAR_alert_email or in an untracked terraform.tfvars file.
variable "alert_email" {
  description = "Email address that receives alerts."
  type        = string
  sensitive   = true
}
