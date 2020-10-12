output "ad-application-id" {
  value = azuread_application.billing.application_id
}

output "ad-application-object-id" {
  value = azuread_application.billing.id
}

output "az-storage-account-id" {
  value = azurerm_storage_account.rg.id
}

output "az-storage-account-primary-conn" {
  value = azurerm_storage_account.rg.primary_connection_string
}

output "az-storage-account-primary-url" {
  value = azurerm_storage_account.rg.primary_web_endpoint
}

output "sas_url_query_string" {
  value = data.azurerm_storage_account_sas.rg.sas
}

output "execout" {
  value = null_resource.kv
}

output "execout-kvssasdef" {
  value = null_resource.kvssasdef
}