locals {
  adls_storage_account_name     = var.adls_storage_account_name_override != "" ? var.adls_storage_account_name_override : lower(replace("${var.deployment_name}-adls", "-", ""))
  adls_filesystem_name          = var.adls_filesystem_name_override != "" ? var.adls_filesystem_name_override : "default"
  adls_private_dns_zone_name    = var.adls_private_dns_zone_name_override != "" ? var.adls_private_dns_zone_name_override : "privatelink.dfs.core.windows.net"
  adls_dns_link_name           = var.adls_dns_link_name_override != "" ? var.adls_dns_link_name_override : "${var.deployment_name}-adls-dns-link"
  adls_private_endpoint_name   = var.adls_private_endpoint_name_override != "" ? var.adls_private_endpoint_name_override : "${var.deployment_name}-adls-pe"
}

resource "azurerm_storage_account" "adls" {
  name                     = local.adls_storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = true  # Hierarchical namespace for ADLS Gen2

  identity {
    type = "SystemAssigned, UserAssigned"
    identity_ids = [var.identity.id]
  }
}

resource "azurerm_storage_data_lake_gen2_filesystem" "adls" {
  name               = local.adls_filesystem_name
  storage_account_id = azurerm_storage_account.adls.id
}

# RBAC Assignments
resource "azurerm_role_assignment" "storage_blob_data_contributor" {
  scope                = azurerm_storage_account.adls.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.identity.principal_id
}

# ============PrivateLink for Storage Account====================
# Private DNS Zone for ADLS
resource "azurerm_private_dns_zone" "adls" {
  name                = local.adls_private_dns_zone_name
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "adls" {
  name                  = local.adls_dns_link_name
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.adls.name
  virtual_network_id    = var.vpc.id
  registration_enabled  = false
}

# Private Endpoint Configuration
resource "azurerm_private_endpoint" "adls" {
  name                = local.adls_private_endpoint_name
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_adls_subnet.id

  private_service_connection {
    name                           = "${var.deployment_name}-adls-psc"
    private_connection_resource_id = azurerm_storage_account.adls.id
    is_manual_connection          = false
    subresource_names            = ["dfs"]
  }

  private_dns_zone_group {
    name                         = "default"
    private_dns_zone_ids        = [azurerm_private_dns_zone.adls.id]
  }
}
