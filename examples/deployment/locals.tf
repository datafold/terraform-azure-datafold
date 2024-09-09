locals {
  deployment_name       = "acme-datafold"
  resource_group_name   = "${local.deployment_name}-rg"
  environment           = "prod"
  provider_region       = "westus"
  azure_tenant_id       = "11111111-2222-3333-4444-555555555555"
  azure_subscription_id = "11111111-2222-3333-4444-555555555555"
  kms_profile           = "target_account_profile"
  kms_key               = "arn:aws:kms:us-west-2:1234567890:alias/acme-datafold"
  domain_name           = "datafold.acme.com"
  clickhouse_data_size  = "40"
  clickhouse_logs_size  = "40"
  redis_data_size       = "10"
  postgres_port         = "5432"
  ssl_cert_name         = "ssl"

  # Common tags to be assigned to all resources
  common_tags = {
    Terraform   = true
    Environment = local.environment
  }
}
