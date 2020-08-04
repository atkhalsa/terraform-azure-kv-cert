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

output "client_cert" {
  value = data.azurerm_key_vault_secret.cert-base64.value
}