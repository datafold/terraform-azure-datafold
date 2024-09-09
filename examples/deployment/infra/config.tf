resource "local_file" "infra_config" {
  filename = "${path.module}/../application/infra.dec.yaml"
  content = templatefile(
    "${path.module}/../templates/infra_settings.tpl",
    {
      aws_target_group_arn           = "",
      clickhouse_access_key          = "",
      clickhouse_secret_key          = "",
      clickhouse_backup_sa           = "",
      clickhouse_data_size           = local.clickhouse_data_size,
      clickhouse_data_volume_id      = "",
      clickhouse_gcs_bucket          = "",
      clickhouse_logs_size           = local.clickhouse_logs_size,
      clickhouse_log_volume_id       = "",
      clickhouse_s3_bucket           = "",
      clickhouse_s3_region           = "",
      clickhouse_azblob_account_name = module.azure[0].azure_blob_account_name,
      clickhouse_azblob_account_key  = module.azure[0].azure_blob_account_key,
      clickhouse_azblob_container    = module.azure[0].azure_blob_container,
      cloud_provider                 = module.azure[0].cloud_provider,
      cluster_name                   = module.azure[0].cluster_name,
      gcp_neg_name                   = "",
      load_balancer_ips              = module.azure[0].load_balancer_ips,
      load_balancer_controller_arn   = "",
      cluster_scaler_role_arn        = "",
      postgres_database              = module.azure[0].postgres_database_name,
      postgres_password              = module.azure[0].postgres_password,
      postgres_port                  = local.postgres_port,
      postgres_server                = module.azure[0].postgres_host,
      postgres_user                  = module.azure[0].postgres_username,
      redis_data_size                = local.redis_data_size,
      redis_data_volume_id           = "",
      server_name                    = module.azure[0].domain_name,
      vpc_cidr                       = module.azure[0].vpc_cidr,
    }
  )

  provisioner "local-exec" {
    environment = {
      "azure_PROFILE" : "${local.kms_profile}",
      "SOPS_KMS_ARN" : "${local.kms_key}"
    }
    command = "sops --aws-profile ${local.kms_profile} --output '${path.module}/../application/infra.yaml' -e '${path.module}/../application/infra.dec.yaml'"
  }

  depends_on = [
    module.azure
  ]
}
