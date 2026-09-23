variable "name_prefix" {
  description = "Prefix for alerting resource names."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group the alert and action group are created in."
  type        = string
}

variable "app_id" {
  description = "ID of the container app the alert watches."
  type        = string
}

variable "alert_email" {
  description = "Email address that receives alerts."
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Tags applied to alerting resources."
  type        = map(string)
}
