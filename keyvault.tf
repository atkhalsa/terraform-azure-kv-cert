resource "azurerm_key_vault" "rg" {
  name                        = "${var.serviceName}-${var.environment}"
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_enabled         = false
  purge_protection_enabled    = false

  sku_name = "standard"

  # network_acls {
  #   default_action = "Deny"
  #   bypass         = "AzureServices"
  # }

  tags = {
    environment = var.environment
    service = var.serviceName
  }
}

resource "azurerm_key_vault_access_policy" "rg" {
  key_vault_id = azurerm_key_vault.rg.id

  tenant_id = data.azurerm_client_config.current.tenant_id
  object_id = data.azurerm_client_config.current.object_id

  certificate_permissions = [
    "create",
    "delete",
    "deleteissuers",
    "get",
    "getissuers",
    "import",
    "list",
    "listissuers",
    "managecontacts",
    "manageissuers",
    "setissuers",
    "update",
  ]

  key_permissions = [
    "backup",
    "create",
    "decrypt",
    "delete",
    "encrypt",
    "get",
    "import",
    "list",
    "purge",
    "recover",
    "restore",
    "sign",
    "unwrapKey",
    "update",
    "verify",
    "wrapKey",
  ]

  secret_permissions = [
    "backup",
    "delete",
    "get",
    "list",
    "purge",
    "recover",
    "restore",
    "set",
  ]

  storage_permissions = [
    "get",
    "getsas",
    "set",
    "setsas",
    "update"
  ]
}

resource "azurerm_key_vault_access_policy" "billing" {
  key_vault_id = azurerm_key_vault.rg.id

  tenant_id = data.azurerm_client_config.current.tenant_id
  object_id = azuread_service_principal.billing.id

  certificate_permissions = [
    "get",
    "getissuers",
    "list",
    "listissuers",
  ]

  key_permissions = [
    "create",
    "update",
    "decrypt",
    "encrypt",
    "get",
    "list",
    "sign",
    "verify",
  ]

  secret_permissions = [
    "get",
    "list",
  ]

  storage_permissions = [
    "get",
    "getsas",
    "set",
    "setsas",
    "update"
  ]
}

resource "azurerm_key_vault_certificate" "rg" {
  name         = "${var.environment}-generated-cert"
  key_vault_id = azurerm_key_vault.rg.id
  depends_on = [azurerm_key_vault_access_policy.rg]

  certificate_policy {
    issuer_parameters {
      name = "Self"
    }

    key_properties {
      exportable = true
      key_size   = 2048
      key_type   = "RSA"
      reuse_key  = true
    }

    lifetime_action {
      action {
        action_type = "AutoRenew"
      }

      trigger {
        days_before_expiry = 30
      }
    }

    secret_properties {
      content_type = "application/x-pkcs12"
    }

    x509_certificate_properties {
      # Server Authentication = 1.3.6.1.5.5.7.3.1
      # Client Authentication = 1.3.6.1.5.5.7.3.2
      extended_key_usage = ["1.3.6.1.5.5.7.3.2"]

      key_usage = [
        "cRLSign",
        "dataEncipherment",
        "digitalSignature",
        "keyAgreement",
        "keyCertSign",
        "keyEncipherment",
      ]

      subject            = "CN=${var.serviceName}-${var.environment}"
      validity_in_months = 24
    }
  }

  tags = {
    environment = var.environment
    service = var.serviceName
  }
}

# # Download the secret in the correct format to upload back to Az Batch
# data "azurerm_key_vault_secret" "cert-base64" {
#   name         = "${var.environment}-generated-cert"
#   key_vault_id = azurerm_key_vault.rg.id
# }

data "azurerm_storage_account_sas" "rg" {
  depends_on = [azurerm_key_vault_access_policy.rg, azurerm_storage_account.rg]
  connection_string = azurerm_storage_account.rg.primary_connection_string
  https_only        = true

  resource_types {
    service   = true
    container = false
    object    = false
  }

  services {
    blob  = false
    queue = true
    table = true
    file  = false
  }

  start  =  var.sas_token_startdate #timestamp()
  expiry = timeadd(var.sas_token_startdate, "${90 * 24 * 2}h")  #60 days

  permissions {
    read    = true
    write   = true
    delete  = true
    list    = true
    add     = true
    create  = true
    update  = true
    process = false
  }
}

# resource "azurerm_key_vault_secret" "sastoken" {
#   name          = "${var.environment}-generated-sastoken"
#   key_vault_id  = azurerm_key_vault.rg.id
#   value         = data.azurerm_storage_account_sas.rg.sas

#   tags = {
#     environment = var.environment
#     service     = var.serviceName
#   }
# }

resource "azurerm_role_assignment" "kv" {
  scope                = data.azurerm_subscription.primary.id
  role_definition_name = "Storage Account Key Operator Service Role"
  principal_id         = "2bfda482-2bd7-4bce-ba28-c6031653846d"
}

# az keyvault storage add --vault-name <YourKeyVaultName> -n <YourStorageAccountName> --active-key-name key1 --auto-regenerate-key --regeneration-period P90D --resource-id "/subscriptions/<subscriptionID>/resourceGroups/<StorageAccountResourceGroupName>/providers/Microsoft.Storage/storageAccounts/<YourStorageAccountName>"

# resource "azurerm_key_vault_managed_storage_account" "kv" {
#   # scope                = data.azurerm_subscription.primary.id
#   # role_definition_name = "Storage Account Key Operator Service Role"
#   # principal_id         = "2bfda482-2bd7-4bce-ba28-c6031653846d"
# }

resource "null_resource" "kv" {
  depends_on = [azurerm_key_vault_access_policy.rg, azurerm_storage_account.rg]
  provisioner "local-exec" {
    command = "az keyvault storage add --vault-name ${azurerm_key_vault.rg.name} -n ${azurerm_storage_account.rg.name} --active-key-name key1 --auto-regenerate-key --regeneration-period P90D --resource-id \"${data.azurerm_subscription.primary.id}/resourceGroups/${azurerm_resource_group.rg.name}/providers/Microsoft.Storage/storageAccounts/${azurerm_storage_account.rg.name}\" > kvstorage.txt"
  }
}

resource "null_resource" "kvssasdef" {
  depends_on = [azurerm_key_vault_access_policy.rg, azurerm_storage_account.rg, data.azurerm_storage_account_sas.rg]
  provisioner "local-exec" {
    command = "az keyvault storage sas-definition create --vault-name ${azurerm_key_vault.rg.name} --account-name ${azurerm_storage_account.rg.name} -n storagesecret --validity-period P90D --sas-type account --template-uri \"${data.azurerm_storage_account_sas.rg.sas}\" > kvstoragesas.txt"
  }
}

# Download the secret in the correct format to upload back to Az Batch. This is work around as azurerm_key_vault_certificate is getting back hex string
# data "azurerm_key_vault_secret" "cert-base64" {
#   name          = "${var.environment}-generated-cert"
#   key_vault_id  = azurerm_key_vault.rg.id
#   depends_on    = [azurerm_key_vault_certificate.rg]
# }

# data "azurerm_key_vault_certificate" "cert" {
#   name          = "${var.environment}-generated-cert"
#   key_vault_id  = azurerm_key_vault.rg.id
#   depends_on    = [azurerm_key_vault_certificate.rg]
# }

# there is limitation and issue related to it https://github.com/terraform-providers/terraform-provider-azurerm/issues/8072
# resource "azuread_application_certificate" "billing" {
#   depends_on            = [azurerm_key_vault_certificate.rg]
#   application_object_id = azuread_application.billing.id
#   type                  = "AsymmetricX509Cert"
#   value                 = data.azurerm_key_vault_secret.cert-base64.value
#   end_date              = azurerm_key_vault_certificate.rg.certificate_attribute.0.expires
# }