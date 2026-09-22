variable "name" {
  description = "Globally unique registry name, 5 to 50 letters and digits."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9]{5,50}$", var.name))
    error_message = "Registry names must be 5 to 50 letters and digits, with no hyphens."
  }
}

variable "resource_group_name" {
  description = "Resource group the registry is created in."
  type        = string
}

variable "location" {
  description = "Azure region for the registry."
  type        = string
}

variable "tags" {
  description = "Tags applied to the registry."
  type        = map(string)
}
