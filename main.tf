# Configure the Azure provider
provider "azurerm" {
  version = "=2.19.0"

  features {}
}

# # Configure the Microsoft Azure Active Directory Provider
# provider "azuread" {
#   version = "=0.7.0"
# }

# # Create an application
# resource "azuread_application" "billing" {
#   name = "billing"
# }

# # Create a service principal
# resource "azuread_service_principal" "billing" {
#   application_id = azuread_application.billing.application_id
# }

data "azurerm_client_config" "current" {}

# Create a new resource group
resource "azurerm_resource_group" "rg" {
    name     = "${var.serviceName}-${var.environment}"
    location = var.location

    tags = {
    environment = var.environment
    service = var.serviceName
  }
}
