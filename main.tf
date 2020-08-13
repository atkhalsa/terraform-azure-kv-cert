# Configure the Azure provider
provider "azurerm" {
  version = "=2.23.0"

  features {}
}

# Configure the Microsoft Azure Active Directory Provider
provider "azuread" {
  version = "=0.11.0"
}

# Create an application
resource "azuread_application" "billing" {
  name = "${var.serviceName}-${var.environment}"
  owners = [data.azurerm_client_config.current.object_id]


  app_role {
    allowed_member_types = [
      "User",
      "Application",
    ]

    description  = "Admins can manage roles and perform all task actions"
    display_name = "Admin"
    is_enabled   = true
    value        = "Admin"
  }

  # required_resource_access {
  #   # Azure Service Management
  #   resource_app_id = "797f4846-ba00-4fd7-ba43-dac1f8f63013"

  #   resource_access {
  #     # user_impersonation
  #     id   = "41094075-9dad-400e-a0bd-54e686782033"
  #     type = "Scope"
  #   }
  # }

  # required_resource_access {
  #   # Microsoft Graph
  #   resource_app_id = "00000003-0000-0000-c000-000000000000"

  #   resource_access {
  #     # IdentityUserFlow.REadAll
  #     id   = "2903d63d-4611-4d43-99ce-a33f3f52e343"
  #     type = "Scope"
  #   }

  #   resource_access {
  #     # User.Read
  #     id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d"
  #     type = "Scope"
  #   }

  #   resource_access {
  #     # Policy.Read.All
  #     id   = "572fea84-0151-49b2-9301-11cb16974376"
  #     type = "Scope"
  #   }

  #   resource_access {
  #     # Application.Read.All
  #     id   = "9a5d68dd-52b0-4cc2-bd40-abcf44ac3a30"
  #     type = "Role"
  #   }

  #   resource_access {
  #     # Application.ReadWrite.All
  #     id   = "1bfefb4e-e0b5-418b-a88f-73c46d2cc8e9"
  #     type = "Role"
  #   }

  #   resource_access {
  #     # Application.ReadWrite.OwnedBy
  #     id   = "18a4783c-866b-4cc7-a460-3d5e5662c884"
  #     type = "Role"
  #   }

  #   resource_access {
  #     #https://graph.microsoft.com/Directory.Read.All
  #     id   = "7ab1d382-f21e-4acd-a863-ba3e13f7da61"
  #     type = "Role"
  #   }
  # }

  required_resource_access {
    # azure key vault
    resource_app_id = "cfa8b339-82a2-471a-a3c9-0fc0be7a4093"

    resource_access {
      # user_impersonation
      id   = "f53da476-18e3-4152-8e01-aec403e6edc0"
      type = "Scope"
    }
  }

  required_resource_access {
    # Azure storage
    resource_app_id = "e406a681-f3d4-42a8-90b6-c2b029497af1"

    resource_access {
      # user_impersonation
      id   = "03e0da56-190b-40ad-a80c-ea378c433f7f"
      type = "Scope"
    }
  }
}

# Create a service principal
resource "azuread_service_principal" "billing" {
  application_id = azuread_application.billing.application_id

  tags = [var.environment, var.serviceName]
}

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
