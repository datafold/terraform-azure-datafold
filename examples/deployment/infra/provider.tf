# This is using the CLI to authenticate
provider "azurerm" {
  tenant_id       = local.azure_tenant_id
  subscription_id = local.azure_subscription_id
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
}

provider "acme" {
  server_url = "https://acme-v02.api.letsencrypt.org/directory"
}
