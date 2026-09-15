terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstateazureaks01"
    container_name       = "tfstate"
    key                  = "azure-aks.tfstate"
    use_cli              = true
  }
}