# TODO: Do not hardcode, but create variables for e.g. version, sku_name, etc.
resource "azurerm_postgresql_flexible_server" "example" {
  name                          = "${var.deployment_name}-db-server"
  resource_group_name           = var.resource_group_name
  location                      = var.location
  version                       = var.postgresql_major_version
  delegated_subnet_id           = var.database_subnet.id
  private_dns_zone_id           = var.private_dns_zone_id
  public_network_access_enabled = false
  administrator_login           = var.database_username
  administrator_password        = random_password.db_password.result
  auto_grow_enabled             = true
  sku_name                      = "GP_Standard_D2s_v3"
  backup_retention_days         = 7
  storage_mb                    = 32768

  tags = var.tags
}

resource "azurerm_postgresql_flexible_server_database" "example" {
  name      = var.database_name
  server_id = azurerm_postgresql_flexible_server.example.id
  collation = "en_US.utf8"
  charset   = "utf8"

  # # prevent the possibility of accidental data loss
  # lifecycle {
  #   prevent_destroy = true
  # }
}
