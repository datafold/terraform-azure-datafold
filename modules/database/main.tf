# Data blocks for existing database resources
data "azurerm_resource_group" "existing" {
  count = var.use_existing_database ? 1 : 0
  name  = var.existing_resource_group_name
}

data "azurerm_postgresql_flexible_server" "existing" {
  count               = var.use_existing_database ? 1 : 0
  name                = var.existing_postgresql_server_name
  resource_group_name = data.azurerm_resource_group.existing[0].name
}

# Note: azurerm_postgresql_flexible_server_database data source doesn't exist in provider
# We'll reference the database name directly from the variable

# Data blocks for existing VNet and networking resources
data "azurerm_resource_group" "existing_vnet" {
  count = var.use_existing_database ? 1 : 0
  name  = var.existing_vnet_resource_group_name
}

data "azurerm_virtual_network" "existing" {
  count               = var.use_existing_database ? 1 : 0
  name                = var.existing_vnet_name
  resource_group_name = data.azurerm_resource_group.existing_vnet[0].name
}

data "azurerm_subnet" "existing_database" {
  count                = var.use_existing_database ? 1 : 0
  name                 = var.existing_database_subnet_name
  virtual_network_name = data.azurerm_virtual_network.existing[0].name
  resource_group_name  = data.azurerm_resource_group.existing_vnet[0].name
}

# Data block for existing private DNS zone
data "azurerm_private_dns_zone" "existing_postgresql" {
  count               = var.use_existing_database ? 1 : 0
  name                = var.existing_private_dns_zone_name
  resource_group_name = data.azurerm_resource_group.existing[0].name
}

locals {
  postgresql_server_name   = var.postgresql_server_name_override != "" ? var.postgresql_server_name_override : "${var.deployment_name}-db-server"
  postgresql_database_name = var.postgresql_database_name_override != "" ? var.postgresql_database_name_override : var.database_name
  postgresql_private_endpoint_name = var.postgresql_private_endpoint_name_override != "" ? var.postgresql_private_endpoint_name_override : "${var.deployment_name}-postgresql-pe"
  vnet_peering_name_prefix = var.postgresql_vnet_peering_name_prefix_override != "" ? var.postgresql_vnet_peering_name_prefix_override : var.deployment_name
}

# VNet Peering from our VNet to existing VNet
resource "azurerm_virtual_network_peering" "ours_to_existing" {
  count                     = var.use_existing_database ? 1 : 0
  name                      = "${local.vnet_peering_name_prefix}-to-${var.existing_vnet_name}"
  resource_group_name       = var.resource_group_name
  virtual_network_name      = var.our_vnet_name
  remote_virtual_network_id = data.azurerm_virtual_network.existing[0].id
  allow_virtual_network_access = true
  allow_forwarded_traffic   = true
  allow_gateway_transit     = false
  use_remote_gateways       = false
}

# VNet Peering from existing VNet to our VNet
resource "azurerm_virtual_network_peering" "existing_to_ours" {
  count                     = var.use_existing_database ? 1 : 0
  name                      = "${var.existing_vnet_name}-to-${local.vnet_peering_name_prefix}"
  resource_group_name       = data.azurerm_resource_group.existing_vnet[0].name
  virtual_network_name      = data.azurerm_virtual_network.existing[0].name
  remote_virtual_network_id = var.our_vnet_id
  allow_virtual_network_access = true
  allow_forwarded_traffic   = true
  allow_gateway_transit     = false
  use_remote_gateways       = false
}

# Note: Using existing private DNS zone instead of creating a new one

# Link existing private DNS zone to our VNet
resource "azurerm_private_dns_zone_virtual_network_link" "postgresql_ours" {
  count                 = var.use_existing_database ? 1 : 0
  name                  = "${var.deployment_name}-postgresql-dns-link-ours"
  resource_group_name   = data.azurerm_resource_group.existing[0].name
  private_dns_zone_name = data.azurerm_private_dns_zone.existing_postgresql[0].name
  virtual_network_id    = var.our_vnet_id
  registration_enabled  = false

  tags = var.tags
}

# Private endpoint in our VNet to connect to existing PostgreSQL server
resource "azurerm_private_endpoint" "postgresql" {
  count               = var.use_existing_database ? 1 : 0
  name                = local.postgresql_private_endpoint_name
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.our_private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.deployment_name}-postgresql-psc"
    private_connection_resource_id = data.azurerm_postgresql_flexible_server.existing[0].id
    subresource_names              = ["postgresqlServer"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "postgresql-dns-zone-group"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.existing_postgresql[0].id]
  }

  tags = var.tags

  depends_on = [
    azurerm_virtual_network_peering.ours_to_existing,
    azurerm_virtual_network_peering.existing_to_ours
  ]
}

# TODO: Do not hardcode, but create variables for e.g. version, sku_name, etc.
resource "azurerm_postgresql_flexible_server" "main" {
  count                         = var.use_existing_database ? 0 : 1
  name                          = local.postgresql_server_name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  version                       = var.postgresql_major_version
  delegated_subnet_id           = var.database_subnet.id
  private_dns_zone_id           = var.private_dns_zone_id
  public_network_access_enabled = false
  administrator_login           = var.database_username
  administrator_password        = random_password.db_password[0].result
  auto_grow_enabled             = true
  sku_name                      = var.database_sku
  backup_retention_days         = var.database_backup_retention_days
  storage_mb                    = var.database_storage_mb

  tags = var.tags
}

resource "azurerm_postgresql_flexible_server_database" "main" {
  count     = var.use_existing_database ? 0 : 1
  name      = local.postgresql_database_name
  server_id = azurerm_postgresql_flexible_server.main[0].id
  collation = "en_US.utf8"
  charset   = "utf8"

  # # prevent the possibility of accidental data loss
  lifecycle {
    prevent_destroy = false
  }
}
