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
