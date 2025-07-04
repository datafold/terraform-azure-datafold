#  ┏┳┓┏━┓╻┏┓╻
#  ┃┃┃┣━┫┃┃┗┫
#  ╹ ╹╹ ╹╹╹ ╹


# ┏━┓╺━┓╻ ╻┏━┓┏━╸
# ┣━┫┏━┛┃ ┃┣┳┛┣╸
# ╹ ╹┗━╸┗━┛╹┗╸┗━╸

locals {
  storage_account_name = replace("${local.deployment_name}-storage", "-", "")
}

module "azure" {
  source  = "datafold/datafold/azure"
  version = "1.0.0"

  providers = {
    azurerm = azurerm
    acme    = acme
  }

  # Common
  deployment_name     = local.deployment_name
  resource_group_name = local.resource_group_name
  environment         = local.environment

  # Provider
  location = local.provider_region

  # Network
  vpc_cidrs           = ["10.0.0.0/16"]  # Choose to align with your IP plan
  jumpbox_custom_data = filebase64("./../templates/datafold/cloud-init.txt")
  domain_name         = local.domain_name

  # Load Balancer
  ssl_cert_name = local.ssl_cert_name

  # Nodes
  node_pool_vm_size = "Standard_E8s_v3"

  service_accounts = {
    "${local.clickhouse_backup_sa}" = {
      namespace             = local.deployment_name
      create_azure_identity = true
      identity_name         = local.clickhouse_backup_sa
      role_assignments = [
        {
          role  = "Storage Blob Data Contributor"
          scope = "/subscriptions/${local.azure_subscription_id}/resourceGroups/${local.resource_group_name}/providers/Microsoft.Storage/storageAccounts/${local.storage_account_name}"
        }
      ]
    },
  }

  # Certificate note
  # Example:
  # [profile acme]
  # role_arn = arn:aws:iam::1234567890:role/ACMERoute53CertificateChallenger
  # source_profile = default
  # region = us-west-2

  acme_provider = "route53"
  acme_config = {
    AWS_PROFILE = "acme"
  }
}
