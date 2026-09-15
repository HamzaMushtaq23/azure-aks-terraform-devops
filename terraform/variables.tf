variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "East Asia"
}

variable "resource_group_name" {
  description = "AKS Resource Group"
  type        = string
  default     = "azure-aks-rg"
}

variable "aks_cluster_name" {
  description = "AKS Cluster Name"
  type        = string
  default     = "azure-aks-cluster"
}

variable "acr_name" {
  description = "Azure Container Registry Name"
  type        = string
  default     = "azureaksacr01"
}

variable "node_count" {
  description = "Number of AKS nodes"
  type        = number
  default     = 1
}

variable "vm_size" {
  description = "AKS node VM size"
  type        = string
  default     = "Standard_B2s_v2"
}