resource "azurerm_storage_account" "rg" {
  name                     = "${lower(replace(var.serviceName, "/[[:^alnum:]]/", ""))}${var.environment}data"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment = var.environment
    service = var.serviceName
  }
}

resource "azurerm_storage_table" "rg" {
  name                  = "usage"
  storage_account_name  = azurerm_storage_account.rg.name
}

resource "azurerm_storage_queue" "rg" {
  name                  = "usage-batch"
  storage_account_name  = azurerm_storage_account.rg.name
}
