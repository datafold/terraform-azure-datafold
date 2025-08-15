resource "random_password" "db_password" {
  count   = var.use_existing_database ? 0 : 1
  length  = 16
  special = false
}
