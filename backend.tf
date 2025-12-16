terraform {
  backend "azurerm" {
    # This will be populated by the CI/CD pipeline or terraform init command
    # storage_account_name = "tfstate..."
    # container_name       = "tfstate"
    # key                  = "fabric/dev/terraform.tfstate"
    # resource_group_name  = "rg-terraform-state"
  }
}
