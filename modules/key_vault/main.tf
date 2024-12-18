
data "azurerm_client_config" "current" {}

locals {
  vault_name           = "${var.deployment_name}-vault"
  vault_truncated_name = substr(local.vault_name, 0, min(length(local.vault_name), 24))
}

resource "azurerm_key_vault" "default" {
  name                = trim(local.vault_truncated_name, "-")
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id

  enabled_for_disk_encryption = true

  sku_name = "standard"

  network_acls {
    bypass         = "AzureServices"
    default_action = "Allow"
  }

  tags = var.tags
}

resource "azurerm_key_vault_access_policy" "parent" {
  key_vault_id = azurerm_key_vault.default.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  key_permissions         = ["Backup", "Create", "Decrypt", "Delete", "Encrypt", "Get", "GetRotationPolicy", "List", "Purge", "Recover", "Restore", "Rotate"]
  secret_permissions      = ["Backup", "Delete", "Get", "List", "Purge", "Recover", "Restore", "Set"]
  storage_permissions     = ["Backup", "Delete", "Get", "List", "Purge", "Recover", "Restore"]
  certificate_permissions = ["Get", "Backup", "Delete", "Create", "List", "Restore", "Purge", "Recover", "Update", "Import"]

  depends_on = [azurerm_key_vault.default]
}

resource "azurerm_key_vault_access_policy" "identity" {
  key_vault_id = azurerm_key_vault.default.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = var.identity.principal_id

  key_permissions         = ["Create", "Decrypt", "Encrypt", "Get", "List"]
  secret_permissions      = ["Delete", "Get", "List", "Purge", "Recover", "Restore", "Set"]
  storage_permissions     = ["Get", "List"]
  certificate_permissions = ["Get", "List"]


  depends_on = [azurerm_key_vault.default]
}

resource "azurerm_key_vault_key" "etcd" {
  depends_on = [azurerm_key_vault_access_policy.parent, azurerm_key_vault_access_policy.identity]

  name         = "generated-etcd-key"
  key_vault_id = azurerm_key_vault.default.id
  key_type     = "RSA"
  key_size     = 2048

  key_opts = ["decrypt", "encrypt", "sign", "unwrapKey", "verify", "wrapKey", ]
}


resource "azurerm_key_vault_certificate" "ssl" {
  name         = "${var.deployment_name}-certificate"
  key_vault_id = azurerm_key_vault.default.id

  certificate {
    contents = acme_certificate.cert.certificate_p12
    password = acme_certificate.cert.certificate_p12_password
  }

  certificate_policy {
    issuer_parameters {
      name = "Unknown"
    }

    key_properties {
      exportable = true
      key_size   = tls_private_key.private_key.rsa_bits
      key_type   = "RSA"
      reuse_key  = false
    }

    secret_properties {
      content_type = "application/x-pkcs12"
    }
  }

  depends_on = [azurerm_key_vault.default, azurerm_key_vault_access_policy.parent]
}