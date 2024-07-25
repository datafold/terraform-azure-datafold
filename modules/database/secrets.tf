resource "random_password" "db_password" {
  length  = 16
  special = false
}