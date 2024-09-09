#  ┏┳┓┏━┓╻┏┓╻
#  ┃┃┃┣━┫┃┃┗┫
#  ╹ ╹╹ ╹╹╹ ╹


# ┏━┓╺━┓╻ ╻┏━┓┏━╸
# ┣━┫┏━┛┃ ┃┣┳┛┣╸
# ╹ ╹┗━╸┗━┛╹┗╸┗━╸

module "azure" {
  source = "./../../../../../../../../terraform-azure-datafold"
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
}
