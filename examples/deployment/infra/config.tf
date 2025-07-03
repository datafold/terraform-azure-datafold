resource "local_file" "infra_config" {
  filename = "${path.module}/../application/infra.dec.yaml"
  content = templatefile(
    "${path.module}/../templates/infra_settings.tpl",
    {
      aws_target_group_arn           = "",
      gcp_backup_account             = "",
      clickhouse_data_size           = local.clickhouse_data_size,
      clickhouse_data_volume_id      = module.azure[0].clickhouse_data_volume_id,
      clickhouse_gcs_bucket          = "",
      clickhouse_logs_size           = local.clickhouse_logs_size,
      clickhouse_log_volume_id       = module.azure[0].clickhouse_logs_volume_id,
      clickhouse_s3_bucket           = "",
      clickhouse_s3_region           = "",
      clickhouse_s3_backup_role      = "",
      clickhouse_azblob_client_id    = try(module.azure[0].service_account_configs[local.clickhouse_backup_sa].azure_identity.client_id, "")
      clickhouse_azblob_account_name = module.azure[0].azure_blob_account_name,
      clickhouse_azblob_container    = module.azure[0].azure_blob_container,
      cloud_provider                 = module.azure[0].cloud_provider,
      cluster_name                   = module.azure[0].cluster_name,
      gcp_neg_name                   = "",
      load_balancer_ips              = [module.azure[0].load_balancer_ips],
      load_balancer_controller_arn   = "",
      cluster_scaler_role_arn        = "",
      postgres_database              = module.azure[0].postgres_database_name,
      postgres_password              = module.azure[0].postgres_password,
      postgres_port                  = local.postgres_port,
      postgres_server                = module.azure[0].postgres_host,
      postgres_user                  = module.azure[0].postgres_username,
      redis_data_size                = local.redis_data_size,
      redis_data_volume_id           = module.azure[0].redis_data_volume_id,
      server_name                    = module.azure[0].domain_name,
      vpc_cidr                       = module.azure[0].vpc_cidr,

      # service accounts vars
      dfshell_role_arn                        = try(module.azure[0].dfshell_role_arn, "")
      dfshell_service_account_name            = try(module.azure[0].dfshell_service_account_name, "datafold-dfshell")
      worker_portal_role_arn                  = try(module.azure[0].worker_portal_role_arn, "")
      worker_portal_service_account_name      = try(module.azure[0].worker_portal_service_account_name, "datafold-worker-portal")
      operator_role_arn                       = try(module.azure[0].operator_role_arn, "")
      operator_service_account_name           = try(module.azure[0].operator_service_account_name, "datafold-operator")
      server_role_arn                         = try(module.azure[0].server_role_arn, "")
      server_service_account_name             = try(module.azure[0].server_service_account_name, "datafold-server")
      scheduler_role_arn                      = try(module.azure[0].scheduler_role_arn, "")
      scheduler_service_account_name          = try(module.azure[0].scheduler_service_account_name, "datafold-scheduler")
      worker_role_arn                         = try(module.azure[0].worker_role_arn, "")
      worker_service_account_name             = try(module.azure[0].worker_service_account_name, "datafold-worker")
      worker_catalog_role_arn                 = try(module.azure[0].worker_catalog_role_arn, "")
      worker_catalog_service_account_name     = try(module.azure[0].worker_catalog_service_account_name, "datafold-worker-catalog")
      worker_interactive_role_arn             = try(module.azure[0].worker_interactive_role_arn, "")
      worker_interactive_service_account_name = try(module.azure[0].worker_interactive_service_account_name, "datafold-worker-interactive")
      worker_singletons_role_arn              = try(module.azure[0].worker_singletons_role_arn, "")
      worker_singletons_service_account_name  = try(module.azure[0].worker_singletons_service_account_name, "datafold-worker-singletons")
      worker_lineage_role_arn                 = try(module.azure[0].worker_lineage_role_arn, "")
      worker_lineage_service_account_name     = try(module.azure[0].worker_lineage_service_account_name, "datafold-worker-lineage")
      worker_monitor_role_arn                 = try(module.azure[0].worker_monitor_role_arn, "")
      worker_monitor_service_account_name     = try(module.azure[0].worker_monitor_service_account_name, "datafold-worker-monitor")
      storage_worker_role_arn                 = try(module.azure[0].storage_worker_role_arn, "")
      storage_worker_service_account_name     = try(module.azure[0].storage_worker_service_account_name, "datafold-storage-worker")
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
