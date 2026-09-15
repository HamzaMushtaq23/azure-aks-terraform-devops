variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "East Asia"
}

variable "state_resource_group_name" {
  description = "Resource group for Terraform state"
  type        = string
  default     = "terraform-state-rg"
}

variable "storage_account_name" {
  description = "Globally unique Storage Account name"
  type        = string
}