=======
# Datafold Azure module

This repository provisions infrastructure resources on Azure for deploying Datafold using the datafold-operator.

## About this module

**⚠️ Important**: This module is now **optional**. If you already have AKS infrastructure in place, you can configure the required resources independently. This module is primarily intended for customers who need to set up the complete infrastructure stack for AKS deployment.

The module provisions Azure infrastructure resources that are required for Datafold deployment. Application configuration is now managed through the `datafoldapplication` custom resource on the cluster using the datafold-operator, rather than through Terraform application directories.

## Breaking Changes

### Application Directory Removal

- The "application" directory is no longer part of this repository
- Application configuration is now managed through the `datafoldapplication` custom resource on the cluster

**Note**: Unlike the AWS module, the Azure module always deploys an Application Gateway as the load balancer. This is because Azure Application Gateway provides better integration with AKS and is the recommended approach for Azure deployments.

## Prerequisites

* An Azure subscription, preferably a new isolated one.
* Terraform >= 1.4.6
* A customer contract with Datafold
  * The application does not work without credentials supplied by sales
* Access to our public helm-charts repository

The full deployment will create the following resources:

* Azure Virtual Network
* Azure subnets
* Azure blob storage for clickhouse backups
* Azure Application Gateway (optional, disabled by default)
* Azure certificate (if load balancer is enabled)
* Azure bastion
* Azure jump VM
* Three Azure managed disks for local data storage
* Azure PostgreSQL database
* An AKS cluster
* Service accounts for the AKS cluster to perform actions outside of its cluster boundary:
  * Provisioning existing managed disks
  * Updating application gateway to point to specific pods in the cluster
  * Rescaling the nodegroup between 1-2 nodes

**Infrastructure Dependencies**: For a complete list of required infrastructure resources and detailed deployment guidance, see the [Datafold Dedicated Cloud Azure Deployment Documentation](https://docs.datafold.com/datafold-deployment/dedicated-cloud/azure).

## Negative scope

* This module will not provision DNS names in your zone.

## How to use this module

* See the example for a potential setup, which has dependencies on our helm-charts

Create the storage account and container for terraform state file:

* Use the files in `bootstrap` to create a terraform state storage account and container.
* Run `./run_bootstrap.sh` to create them. Enter the deployment_name when the question is asked.
  * The `deployment_name` is important. This is used for the k8s namespace and datadog unified logging tags and other places.
  * Suggestion: `company-datafold`
* Transfer the name of that storage account and container into the `backend.hcl`
* Set the `resource_group_name` and `location` where the storage account is stored.
* `backend.hcl` is only about where the terraform state file is located.

The example directory contains a single deployment example for infrastructure setup.

Setting up the infrastructure:

* It is easiest if you have full admin access in the target subscription.
* Pre-create a symmetric encryption key that is used to encrypt/decrypt secrets of this deployment.
  * Use the alias instead of the `mrk` link. Put that into `locals.tf`
* **Certificate Requirements**: Pre-create and validate the certificate in your DNS, then refer to that certificate in main.tf using its domain name (Replace "datafold.acme.com")
* Change the settings in locals.tf
  * provider_region = which region you want to deploy in.
  * resource_group_name = The resource group in which to deploy.
  * kms_profile = Can be the same profile, unless you want the encryption key elsewhere.
  * kms_key = A pre-created symmetric KMS key. It's only purpose is for encryption/decryption of deployment secrets.
  * deployment_name = The name of the deployment, used in kubernetes namespace, container naming and datadog "deployment" Unified Tag)
  * azure_tenant_id = The tenant ID where to deploy.
  * azure_subscription_id = The ID of the subscription to deploy in.
* Run `terraform init -backend-config=../backend.hcl` in the infra directory.

* Run `terraform apply` in `infra` directory. This should complete ok. 
  * Check in the console if you see the AKS cluster, PostgreSQL database, etc.
  * If you enabled load balancer deployment, check for the Application Gateway as well.
  * The configuration values needed for application deployment will be output to the console after the apply completes.

**Application Deployment**: After infrastructure is ready, deploy the application using the datafold-operator. Continue with the [Datafold Helm Charts repository](https://github.com/datafold/helm-charts) to deploy the operator manager and then the application through the operator. The operator is the default and recommended method for deploying Datafold.

## Infrastructure Dependencies

This module is designed to provide the complete infrastructure stack for Datafold deployment. However, if you already have AKS infrastructure in place, you can choose to configure the required resources independently.

**Required Infrastructure Components**:
- AKS cluster with appropriate node pools
- Azure Database for PostgreSQL
- Azure Storage account for ClickHouse backups
- Azure managed disks for persistent storage (ClickHouse data, ClickHouse logs, Redis data)
- Managed identities and role assignments for cluster operations
- Azure Application Gateway (always deployed by this module)
- Virtual Network and networking components
- SSL certificate (must be pre-created and validated)

**Alternative Approaches**:
- **Use this module**: Provides complete infrastructure setup for new deployments
- **Use existing infrastructure**: Configure required resources manually or through other means
- **Hybrid approach**: Use this module for some components and existing infrastructure for others

For detailed specifications of each required component, see the [Datafold Dedicated Cloud Azure Deployment Documentation](https://docs.datafold.com/datafold-deployment/dedicated-cloud/azure). For application deployment instructions, continue with the [Datafold Helm Charts repository](https://github.com/datafold/helm-charts) to deploy the operator manager and then the application through the operator.

## Resource Name Customization

The terraform-azure-datafold module provides 41 resource name override variables that allow you to customize resource names according to your organization's naming standards or compliance requirements.

### Key Benefits
- **Compliance**: Meet organizational naming conventions
- **Environment Separation**: Different naming patterns for dev/staging/prod
- **Multi-tenant**: Unique identifiers for different customers/teams
- **Integration**: Match existing resource naming patterns

### Quick Example
```hcl
module "azure" {
  source = "datafold/datafold/azure"

  # Standard configuration...
  deployment_name = "example-datafold"

  # Custom resource group name (set directly, no override needed)
  resource_group_name   = "prod-acme-datafold-rg"
  create_resource_group = false

  # Custom resource names via overrides
  aks_cluster_name_override     = "prod-acme-datafold-aks"
  storage_account_name_override = "prodacmedatafoldstorage"
  key_vault_name_override       = "prod-acme-datafold-kv"
  virtual_network_name_override = "prod-acme-datafold-vnet"
}
```

### Important Notes
- **Azure Storage Accounts**: Max 24 chars, lowercase letters/numbers only
- **Key Vault Names**: Max 24 chars, alphanumeric and hyphens only
- **Service Account Scopes**: Update role assignment scopes when using overrides
- **Storage Account Consistency**: When overriding storage account names, ensure service account scopes reference the same name to avoid permission errors

📖 **For complete documentation and examples**, see [examples/README.md](./examples/README.md)

### How to connect to the private AKS cluster

Connecting to the AKS cluster requires 3 terminals in total.

1. The first terminal is set up to access the VPC through the bastion.
2. The second sets up a tunnel to the jumpbox.
3. The third terminal is the one doing the work.

```bash
# Set up Kube config
deployment_name="acme-datafold"
proxy_port="1081"
az aks get-credentials --resource-group "${deployment_name}-rg" --name "${deployment_name}-cluster"
kubectl config set clusters.azure-dev-datafold-cluster.proxy-url "socks5://localhost:${proxy_port}"
kubectl config set-context --current --namespace="${deployment_name}"

 # Run in terminal 1: Open an Azure Bastion tunnel into VM
deployment_name="acme-datafold"
target="jumpbox-vm"
vm_id=$(az vm list --resource-group "${deployment_name}-rg" | jq -r '.[].id' | grep "${deployment_name}-${target}")
az network bastion tunnel --name "bastion" --resource-group "${deployment_name}-rg" --target-resource-id "${vm_id}" --resource-port 22 --port 50022

# Run in terminal 2 (authorized_keys are passed on by cloud-init.txt file/jumpbox_custom_data):
proxy_port="1081"
ssh -i ~/.ssh/id_rsa -D $proxy_port -p 50022 adminuser@127.0.0.1 -N

# Run in terminal 3:
k9s
```

### Initializing the application

After deploying the application through the operator (see the [Datafold Helm Charts repository](https://github.com/datafold/helm-charts)), establish a shell into the `<deployment>-dfshell` container. 
It is likely that the scheduler and server containers are crashing in a loop.

All we need to do is to run these commands:

1. `./manage.py clickhouse create-tables`
2. `./manage.py database create-or-upgrade`
3. `./manage.py installation set-new-deployment-params`

Now all containers should be up and running.

## More information

You can get more information from our documentation site:

https://docs.datafold.com/datafold-deployment/dedicated-cloud/azure

<!-- BEGIN_TF_DOCS -->

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_acme"></a> [acme](#requirement\_acme) | ~> 2.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~>4.35.0 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | ~> 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | ~>4.35.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_aks"></a> [aks](#module\_aks) | ./modules/aks | n/a |
| <a name="module_clickhouse_backup"></a> [clickhouse\_backup](#module\_clickhouse\_backup) | ./modules/clickhouse_backup | n/a |
| <a name="module_data_lake"></a> [data\_lake](#module\_data\_lake) | ./modules/data_lake | n/a |
| <a name="module_database"></a> [database](#module\_database) | ./modules/database | n/a |
| <a name="module_identity"></a> [identity](#module\_identity) | ./modules/identity | n/a |
| <a name="module_key_vault"></a> [key\_vault](#module\_key\_vault) | ./modules/key_vault | n/a |
| <a name="module_load_balancer"></a> [load\_balancer](#module\_load\_balancer) | ./modules/load_balancer | n/a |
| <a name="module_networking"></a> [networking](#module\_networking) | ./modules/networking | n/a |

## Resources

| Name | Type |
|------|------|
| [azurerm_resource_group.default](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_acme_config"></a> [acme\_config](#input\_acme\_config) | The configuration for the provider of the DNS challenge | `any` | n/a | yes |
| <a name="input_acme_provider"></a> [acme\_provider](#input\_acme\_provider) | The name of the provider for the DNS challenge | `string` | n/a | yes |
| <a name="input_adls_dns_link_name_override"></a> [adls\_dns\_link\_name\_override](#input\_adls\_dns\_link\_name\_override) | Override for the name used in resource.azurerm\_private\_dns\_zone\_virtual\_network\_link.adls (modules/data\_lake) | `string` | `""` | no |
| <a name="input_adls_filesystem_name_override"></a> [adls\_filesystem\_name\_override](#input\_adls\_filesystem\_name\_override) | Override for the name used in resource.azurerm\_storage\_data\_lake\_gen2\_filesystem.adls (modules/data\_lake) | `string` | `""` | no |
| <a name="input_adls_private_dns_zone_name_override"></a> [adls\_private\_dns\_zone\_name\_override](#input\_adls\_private\_dns\_zone\_name\_override) | Override for the name used in resource.azurerm\_private\_dns\_zone.adls (modules/data\_lake) | `string` | `""` | no |
| <a name="input_adls_private_endpoint_name_override"></a> [adls\_private\_endpoint\_name\_override](#input\_adls\_private\_endpoint\_name\_override) | Override for the name used in resource.azurerm\_private\_endpoint.adls (modules/data\_lake) | `string` | `""` | no |
| <a name="input_adls_storage_account_name_override"></a> [adls\_storage\_account\_name\_override](#input\_adls\_storage\_account\_name\_override) | Override for the name used in resource.azurerm\_storage\_account.adls (modules/data\_lake) | `string` | `""` | no |
| <a name="input_aks_cluster_name_override"></a> [aks\_cluster\_name\_override](#input\_aks\_cluster\_name\_override) | Override for the name used in resource.azurerm\_kubernetes\_cluster.default (modules/aks) | `string` | `""` | no |
| <a name="input_aks_dns_prefix_override"></a> [aks\_dns\_prefix\_override](#input\_aks\_dns\_prefix\_override) | Override for the dns\_prefix used in resource.azurerm\_kubernetes\_cluster.default (modules/aks) | `string` | `""` | no |
| <a name="input_aks_dns_service_ip"></a> [aks\_dns\_service\_ip](#input\_aks\_dns\_service\_ip) | The IP address for the Kubernetes DNS service | `string` | `"172.16.0.10"` | no |
| <a name="input_aks_service_cidr"></a> [aks\_service\_cidr](#input\_aks\_service\_cidr) | The CIDR block for the Kubernetes services | `string` | `"172.16.0.0/16"` | no |
| <a name="input_aks_sku_tier"></a> [aks\_sku\_tier](#input\_aks\_sku\_tier) | The SKU tier for the cluster | `string` | `"Free"` | no |
| <a name="input_aks_subnet_cidrs"></a> [aks\_subnet\_cidrs](#input\_aks\_subnet\_cidrs) | The CIDR block for the AKS subnet. If empty it will be calculated from the VPC CIDR and given size. | `list(string)` | `[]` | no |
| <a name="input_aks_subnet_name_override"></a> [aks\_subnet\_name\_override](#input\_aks\_subnet\_name\_override) | Override for the name used in resource.azurerm\_subnet.aks\_subnet (modules/networking) | `string` | `""` | no |
| <a name="input_aks_subnet_size"></a> [aks\_subnet\_size](#input\_aks\_subnet\_size) | The size of the AKS subnet in number of IPs | `number` | `1024` | no |
| <a name="input_aks_workload_identity_enabled"></a> [aks\_workload\_identity\_enabled](#input\_aks\_workload\_identity\_enabled) | Flag to enable workload identity | `bool` | `true` | no |
| <a name="input_app_gw_subnet_cidrs"></a> [app\_gw\_subnet\_cidrs](#input\_app\_gw\_subnet\_cidrs) | The CIDR block for the app gateway subnet. If empty it will be calculated from the VPC CIDR and given size. | `list(string)` | `[]` | no |
| <a name="input_app_gw_subnet_name_override"></a> [app\_gw\_subnet\_name\_override](#input\_app\_gw\_subnet\_name\_override) | Override for the name used in resource.azurerm\_subnet.app\_gw\_subnet (modules/networking) | `string` | `""` | no |
| <a name="input_app_gw_subnet_size"></a> [app\_gw\_subnet\_size](#input\_app\_gw\_subnet\_size) | The size of the app gateway subnet in number of IPs | `number` | `256` | no |
| <a name="input_app_subnet_cidrs"></a> [app\_subnet\_cidrs](#input\_app\_subnet\_cidrs) | The CIDR block for the app subnet. If empty it will be calculated from the VPC CIDR and given size. | `list(string)` | `[]` | no |
| <a name="input_app_subnet_name_override"></a> [app\_subnet\_name\_override](#input\_app\_subnet\_name\_override) | Override for the name used in resource.azurerm\_subnet.app\_subnet (modules/networking) | `string` | `""` | no |
| <a name="input_app_subnet_size"></a> [app\_subnet\_size](#input\_app\_subnet\_size) | The size of the app subnet in number of IPs | `number` | `256` | no |
| <a name="input_application_gateway_name_override"></a> [application\_gateway\_name\_override](#input\_application\_gateway\_name\_override) | Override for the name used in resource.azurerm\_application\_gateway.default (modules/load\_balancer) | `string` | `""` | no |
| <a name="input_azure_bastion_subnet_cidrs"></a> [azure\_bastion\_subnet\_cidrs](#input\_azure\_bastion\_subnet\_cidrs) | The CIDR block for the Azure Bastion subnet. If empty it will be calculated from the VPC CIDR and given size. | `list(string)` | `[]` | no |
| <a name="input_azure_bastion_subnet_name_override"></a> [azure\_bastion\_subnet\_name\_override](#input\_azure\_bastion\_subnet\_name\_override) | Override for the name used in resource.azurerm\_subnet.azure\_bastion\_subnet (modules/networking) | `string` | `""` | no |
| <a name="input_azure_bastion_subnet_size"></a> [azure\_bastion\_subnet\_size](#input\_azure\_bastion\_subnet\_size) | The size of the Azure Bastion subnet in number of IPs | `number` | `256` | no |
| <a name="input_bastion_host_name_override"></a> [bastion\_host\_name\_override](#input\_bastion\_host\_name\_override) | Override for the name used in resource.azurerm\_bastion\_host.bastion (modules/networking) | `string` | `""` | no |
| <a name="input_bastion_public_ip_name_override"></a> [bastion\_public\_ip\_name\_override](#input\_bastion\_public\_ip\_name\_override) | Override for the name used in resource.azurerm\_public\_ip.ip\_bastion\_host (modules/networking) | `string` | `""` | no |
| <a name="input_ch_data_disk_iops"></a> [ch\_data\_disk\_iops](#input\_ch\_data\_disk\_iops) | IOPS of volume | `number` | `3000` | no |
| <a name="input_ch_data_disk_throughput"></a> [ch\_data\_disk\_throughput](#input\_ch\_data\_disk\_throughput) | Throughput of volume | `number` | `1000` | no |
| <a name="input_ch_logs_disk_iops"></a> [ch\_logs\_disk\_iops](#input\_ch\_logs\_disk\_iops) | IOPS of volume | `number` | `3000` | no |
| <a name="input_ch_logs_disk_throughput"></a> [ch\_logs\_disk\_throughput](#input\_ch\_logs\_disk\_throughput) | Throughput of volume | `number` | `250` | no |
| <a name="input_clickhouse_backup_container_name_override"></a> [clickhouse\_backup\_container\_name\_override](#input\_clickhouse\_backup\_container\_name\_override) | Override for the name used in resource.azurerm\_storage\_container.clickhouse\_backup (modules/clickhouse\_backup) | `string` | `""` | no |
| <a name="input_clickhouse_data_disk_name_override"></a> [clickhouse\_data\_disk\_name\_override](#input\_clickhouse\_data\_disk\_name\_override) | Override for the name used in resource.azurerm\_managed\_disk.clickhouse\_data | `string` | `""` | no |
| <a name="input_clickhouse_data_size"></a> [clickhouse\_data\_size](#input\_clickhouse\_data\_size) | ClickHouse data disk size in GB | `number` | `40` | no |
| <a name="input_clickhouse_logs_disk_name_override"></a> [clickhouse\_logs\_disk\_name\_override](#input\_clickhouse\_logs\_disk\_name\_override) | Override for the name used in resource.azurerm\_managed\_disk.clickhouse\_logs | `string` | `""` | no |
| <a name="input_clickhouse_logs_size"></a> [clickhouse\_logs\_size](#input\_clickhouse\_logs\_size) | ClickHouse logs disk size in GB | `number` | `40` | no |
| <a name="input_create_adls"></a> [create\_adls](#input\_create\_adls) | Whether to create Azure Data Lake Storage | `bool` | `false` | no |
| <a name="input_create_database"></a> [create\_database](#input\_create\_database) | Flag to toggle PostgreSQL database creation | `bool` | `true` | no |
| <a name="input_create_resource_group"></a> [create\_resource\_group](#input\_create\_resource\_group) | Flag to toggle resource group creation | `bool` | `true` | no |
| <a name="input_custom_node_pools"></a> [custom\_node\_pools](#input\_custom\_node\_pools) | Dynamic extra node pools | <pre>list(object({<br>    name = string<br>    enabled = bool<br>    initial_node_count = number<br>    vm_size = string<br>    disk_size_gb = number<br>    disk_type = string<br>    taints = list(object({<br>      key    = string<br>      value  = string<br>      effect = string<br>    }))<br>    spot            = bool<br>    min_node_count  = number<br>    max_node_count  = number<br>    max_surge       = number<br>    labels          = map(string)<br>  }))</pre> | `[]` | no |
| <a name="input_database_backup_retention_days"></a> [database\_backup\_retention\_days](#input\_database\_backup\_retention\_days) | PostgreSQL backup retention days | `number` | `7` | no |
| <a name="input_database_dns_link_name_override"></a> [database\_dns\_link\_name\_override](#input\_database\_dns\_link\_name\_override) | Override for the name used in resource.azurerm\_private\_dns\_zone\_virtual\_network\_link.database (modules/networking) | `string` | `""` | no |
| <a name="input_database_name"></a> [database\_name](#input\_database\_name) | Postgres database name | `string` | `"datafold"` | no |
| <a name="input_database_private_dns_zone_name_override"></a> [database\_private\_dns\_zone\_name\_override](#input\_database\_private\_dns\_zone\_name\_override) | Override for the name used in resource.azurerm\_private\_dns\_zone.database (modules/networking) | `string` | `""` | no |
| <a name="input_database_sku"></a> [database\_sku](#input\_database\_sku) | PostgreSQL SKU | `string` | `"GP_Standard_D2s_v3"` | no |
| <a name="input_database_storage_mb"></a> [database\_storage\_mb](#input\_database\_storage\_mb) | PostgreSQL storage in MB. One of a predetermined set of values, see: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_flexible_server#storage_mb | `number` | `32768` | no |
| <a name="input_database_subnet_cidrs"></a> [database\_subnet\_cidrs](#input\_database\_subnet\_cidrs) | The CIDR block for the database subnet. If empty it will be calculated from the VPC CIDR and given size. | `list(string)` | `[]` | no |
| <a name="input_database_subnet_name_override"></a> [database\_subnet\_name\_override](#input\_database\_subnet\_name\_override) | Override for the name used in resource.azurerm\_subnet.database\_subnet (modules/networking) | `string` | `""` | no |
| <a name="input_database_subnet_size"></a> [database\_subnet\_size](#input\_database\_subnet\_size) | The size of the database subnet in number of IPs | `number` | `256` | no |
| <a name="input_database_username"></a> [database\_username](#input\_database\_username) | ProgreSQL username | `string` | `"datafold"` | no |
| <a name="input_deploy_lb"></a> [deploy\_lb](#input\_deploy\_lb) | Flag to toggle load balancer creation. When false, load balancer should be deployed via helm-charts/kubernetes. | `bool` | `true` | no |
| <a name="input_deployment_name"></a> [deployment\_name](#input\_deployment\_name) | The name of the deployment | `string` | n/a | yes |
| <a name="input_disk_sku"></a> [disk\_sku](#input\_disk\_sku) | Disk SKU type | `string` | `"StandardSSD_LRS"` | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | The domain name for the load balancer. E.g. azure-dev.datafold.io | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | The environment for the resources | `string` | `"dev"` | no |
| <a name="input_etcd_key_name_override"></a> [etcd\_key\_name\_override](#input\_etcd\_key\_name\_override) | Override for the name used in resource.azurerm\_key\_vault\_key.etcd (modules/key\_vault) | `string` | `""` | no |
| <a name="input_gw_private_ip_address"></a> [gw\_private\_ip\_address](#input\_gw\_private\_ip\_address) | The private IP address of the gateway. Should be within the gateway subnet CIDR range. | `string` | `"10.0.9.10"` | no |
| <a name="input_identity_name_override"></a> [identity\_name\_override](#input\_identity\_name\_override) | Override for the name used in resource.azurerm\_user\_assigned\_identity.default (modules/identity) | `string` | `""` | no |
| <a name="input_jumpbox_custom_data"></a> [jumpbox\_custom\_data](#input\_jumpbox\_custom\_data) | Custom data for the jumpbox. Can be used to e.g. pass on ~/.ssh/authorized\_keys with a cloud-init script. | `string` | `""` | no |
| <a name="input_jumpbox_nsg_name_override"></a> [jumpbox\_nsg\_name\_override](#input\_jumpbox\_nsg\_name\_override) | Override for the name used in resource.azurerm\_network\_security\_group.jumpbox (modules/networking) | `string` | `""` | no |
| <a name="input_jumpbox_public_ip_name_override"></a> [jumpbox\_public\_ip\_name\_override](#input\_jumpbox\_public\_ip\_name\_override) | Override for the name used in resource.azurerm\_public\_ip.jumpbox (modules/networking) | `string` | `""` | no |
| <a name="input_k8s_public_access_cidrs"></a> [k8s\_public\_access\_cidrs](#input\_k8s\_public\_access\_cidrs) | List of CIDRs that are allowed to connect to the EKS control plane | `list(string)` | n/a | yes |
| <a name="input_key_vault_name_override"></a> [key\_vault\_name\_override](#input\_key\_vault\_name\_override) | Override for the name used in resource.azurerm\_key\_vault.default (modules/key\_vault) | `string` | `""` | no |
| <a name="input_lb_is_public"></a> [lb\_is\_public](#input\_lb\_is\_public) | Flag that determines if LB is public | `bool` | `true` | no |
| <a name="input_linux_vm_name_override"></a> [linux\_vm\_name\_override](#input\_linux\_vm\_name\_override) | Override for the name used in resource.azurerm\_linux\_virtual\_machine.linux\_vm (modules/networking) | `string` | `""` | no |
| <a name="input_location"></a> [location](#input\_location) | The Azure location where the resources will be created | `string` | `""` | no |
| <a name="input_max_node_count"></a> [max\_node\_count](#input\_max\_node\_count) | n/a | `number` | `6` | no |
| <a name="input_max_pods"></a> [max\_pods](#input\_max\_pods) | The maximum number of pods that can run on a node | `number` | `50` | no |
| <a name="input_min_node_count"></a> [min\_node\_count](#input\_min\_node\_count) | n/a | `number` | `1` | no |
| <a name="input_node_pool_name"></a> [node\_pool\_name](#input\_node\_pool\_name) | The name of the node pool | `string` | `"default"` | no |
| <a name="input_node_pool_node_count"></a> [node\_pool\_node\_count](#input\_node\_pool\_node\_count) | The number of nodes in the pool | `number` | `1` | no |
| <a name="input_node_pool_vm_size"></a> [node\_pool\_vm\_size](#input\_node\_pool\_vm\_size) | The size of the VMs in the pool | `string` | `"Standard_DS2_v2"` | no |
| <a name="input_postgresql_database_name_override"></a> [postgresql\_database\_name\_override](#input\_postgresql\_database\_name\_override) | Override for the name used in resource.azurerm\_postgresql\_flexible\_server\_database.main (modules/database) | `string` | `""` | no |
| <a name="input_postgresql_major_version"></a> [postgresql\_major\_version](#input\_postgresql\_major\_version) | PostgreSQL major version | `string` | `"15"` | no |
| <a name="input_postgresql_server_name_override"></a> [postgresql\_server\_name\_override](#input\_postgresql\_server\_name\_override) | Override for the name used in resource.azurerm\_postgresql\_flexible\_server.main (modules/database) | `string` | `""` | no |
| <a name="input_private_cluster_enabled"></a> [private\_cluster\_enabled](#input\_private\_cluster\_enabled) | Flag to enable private cluster | `bool` | `true` | no |
| <a name="input_private_endpoint_adls_subnet_cidrs"></a> [private\_endpoint\_adls\_subnet\_cidrs](#input\_private\_endpoint\_adls\_subnet\_cidrs) | List of subnet CIDRs for ADLS private endpoints | `list(string)` | `[]` | no |
| <a name="input_private_endpoint_adls_subnet_name_override"></a> [private\_endpoint\_adls\_subnet\_name\_override](#input\_private\_endpoint\_adls\_subnet\_name\_override) | Override for the name used in resource.azurerm\_subnet.private\_endpoint\_adls (modules/networking) | `string` | `""` | no |
| <a name="input_private_endpoint_adls_subnet_size"></a> [private\_endpoint\_adls\_subnet\_size](#input\_private\_endpoint\_adls\_subnet\_size) | Size of the ADLS subnet (number of IP addresses) | `number` | `256` | no |
| <a name="input_private_endpoint_storage_subnet_cidrs"></a> [private\_endpoint\_storage\_subnet\_cidrs](#input\_private\_endpoint\_storage\_subnet\_cidrs) | The CIDR block for the private endpoint storage subnet. If empty it will be calculated from the VPC CIDR and given size. | `list(string)` | `[]` | no |
| <a name="input_private_endpoint_storage_subnet_name_override"></a> [private\_endpoint\_storage\_subnet\_name\_override](#input\_private\_endpoint\_storage\_subnet\_name\_override) | Override for the name used in resource.azurerm\_subnet.private\_endpoint\_storage (modules/networking) | `string` | `""` | no |
| <a name="input_private_endpoint_storage_subnet_size"></a> [private\_endpoint\_storage\_subnet\_size](#input\_private\_endpoint\_storage\_subnet\_size) | The size of the private endpoint storage subnet in number of IPs | `number` | `256` | no |
| <a name="input_public_ip_name_override"></a> [public\_ip\_name\_override](#input\_public\_ip\_name\_override) | Override for the name used in resource.azurerm\_public\_ip.default (modules/networking) | `string` | `""` | no |
| <a name="input_redis_data_disk_name_override"></a> [redis\_data\_disk\_name\_override](#input\_redis\_data\_disk\_name\_override) | Override for the name used in resource.azurerm\_managed\_disk.redis\_data | `string` | `""` | no |
| <a name="input_redis_data_size"></a> [redis\_data\_size](#input\_redis\_data\_size) | Redis data disk size in GB | `number` | `50` | no |
| <a name="input_redis_disk_iops"></a> [redis\_disk\_iops](#input\_redis\_disk\_iops) | IOPS of redis volume | `number` | `3000` | no |
| <a name="input_redis_disk_throughput"></a> [redis\_disk\_throughput](#input\_redis\_disk\_throughput) | Throughput of redis volume | `number` | `125` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | The name of the resource group where the resources will be created | `string` | `""` | no |
| <a name="input_resource_group_tags"></a> [resource\_group\_tags](#input\_resource\_group\_tags) | The tags to apply to the resource group | `map(string)` | `{}` | no |
| <a name="input_service_accounts"></a> [service\_accounts](#input\_service\_accounts) | Map of service accounts and their configuration | <pre>map(object({<br>    namespace             = string<br>    create_azure_identity = bool<br>    identity_name         = optional(string)<br>    role_assignments      = optional(list(object({<br>      role  = string<br>      scope = string<br>    })), [])<br>  }))</pre> | `{}` | no |
| <a name="input_ssl_cert_name"></a> [ssl\_cert\_name](#input\_ssl\_cert\_name) | The name of the SSL certificate to use for the load balancer. This needs to be referenced by the k8s azure-application-gateway ingress config. | `string` | n/a | yes |
| <a name="input_ssl_certificate_name_override"></a> [ssl\_certificate\_name\_override](#input\_ssl\_certificate\_name\_override) | Override for the name used in resource.azurerm\_key\_vault\_certificate.ssl (modules/key\_vault) | `string` | `""` | no |
| <a name="input_storage_account_name_override"></a> [storage\_account\_name\_override](#input\_storage\_account\_name\_override) | Override for the name used in resource.azurerm\_storage\_account.storage (modules/clickhouse\_backup) | `string` | `""` | no |
| <a name="input_storage_dns_link_name_override"></a> [storage\_dns\_link\_name\_override](#input\_storage\_dns\_link\_name\_override) | Override for the name used in resource.azurerm\_private\_dns\_zone\_virtual\_network\_link.storage\_account\_link (modules/clickhouse\_backup) | `string` | `""` | no |
| <a name="input_storage_private_dns_zone_name_override"></a> [storage\_private\_dns\_zone\_name\_override](#input\_storage\_private\_dns\_zone\_name\_override) | Override for the name used in resource.azurerm\_private\_dns\_zone.storage\_account\_dns (modules/clickhouse\_backup) | `string` | `""` | no |
| <a name="input_storage_private_endpoint_name_override"></a> [storage\_private\_endpoint\_name\_override](#input\_storage\_private\_endpoint\_name\_override) | Override for the name used in resource.azurerm\_private\_endpoint.storage (modules/clickhouse\_backup) | `string` | `""` | no |
| <a name="input_virtual_network_name_override"></a> [virtual\_network\_name\_override](#input\_virtual\_network\_name\_override) | Override for the name used in resource.azurerm\_virtual\_network.vnet (modules/networking) | `string` | `""` | no |
| <a name="input_virtual_network_tags"></a> [virtual\_network\_tags](#input\_virtual\_network\_tags) | The tags to apply to the virtual network | `map(string)` | `{}` | no |
| <a name="input_vm_bastion_subnet_cidrs"></a> [vm\_bastion\_subnet\_cidrs](#input\_vm\_bastion\_subnet\_cidrs) | The CIDR block for the VM Bastion subnet. If empty it will be calculated from the VPC CIDR and given size. | `list(string)` | `[]` | no |
| <a name="input_vm_bastion_subnet_name_override"></a> [vm\_bastion\_subnet\_name\_override](#input\_vm\_bastion\_subnet\_name\_override) | Override for the name used in resource.azurerm\_subnet.vm\_bastion\_subnet (modules/networking) | `string` | `""` | no |
| <a name="input_vm_bastion_subnet_size"></a> [vm\_bastion\_subnet\_size](#input\_vm\_bastion\_subnet\_size) | The size of the VM Bastion subnet in number of IPs | `number` | `256` | no |
| <a name="input_vm_nic_name_override"></a> [vm\_nic\_name\_override](#input\_vm\_nic\_name\_override) | Override for the name used in resource.azurerm\_network\_interface.vm\_nic (modules/networking) | `string` | `""` | no |
| <a name="input_vnet_nsg_name_override"></a> [vnet\_nsg\_name\_override](#input\_vnet\_nsg\_name\_override) | Override for the name used in resource.azurerm\_network\_security\_group.nsg\_vnet (modules/networking) | `string` | `""` | no |
| <a name="input_vpc_cidrs"></a> [vpc\_cidrs](#input\_vpc\_cidrs) | The address space for the virtual network | `list(string)` | <pre>[<br>  "10.0.0.0/16"<br>]</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_adls_account_key"></a> [adls\_account\_key](#output\_adls\_account\_key) | The access key for the Azure Data Lake Storage account |
| <a name="output_adls_account_name"></a> [adls\_account\_name](#output\_adls\_account\_name) | The name of the Azure Data Lake Storage account |
| <a name="output_adls_filesystem"></a> [adls\_filesystem](#output\_adls\_filesystem) | The filesystem details for the Azure Data Lake Storage |
| <a name="output_azure_blob_account_key"></a> [azure\_blob\_account\_key](#output\_azure\_blob\_account\_key) | The access key for the Azure Blob Storage account |
| <a name="output_azure_blob_account_name"></a> [azure\_blob\_account\_name](#output\_azure\_blob\_account\_name) | The name of the Azure Blob Storage account |
| <a name="output_azure_blob_container"></a> [azure\_blob\_container](#output\_azure\_blob\_container) | The name of the Azure Blob Storage container |
| <a name="output_clickhouse_data_volume_id"></a> [clickhouse\_data\_volume\_id](#output\_clickhouse\_data\_volume\_id) | The volume ID where clickhouse data will be stored. |
| <a name="output_clickhouse_logs_volume_id"></a> [clickhouse\_logs\_volume\_id](#output\_clickhouse\_logs\_volume\_id) | The volume ID where clickhouse logs will be stored. |
| <a name="output_cloud_provider"></a> [cloud\_provider](#output\_cloud\_provider) | The cloud provider being used (always 'azure' for this module) |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | The name of the AKS cluster |
| <a name="output_domain_name"></a> [domain\_name](#output\_domain\_name) | The domain name configured for the deployment |
| <a name="output_load_balancer_ips"></a> [load\_balancer\_ips](#output\_load\_balancer\_ips) | The public IP addresses assigned to the load balancer |
| <a name="output_postgres_database_name"></a> [postgres\_database\_name](#output\_postgres\_database\_name) | The name of the PostgreSQL database |
| <a name="output_postgres_host"></a> [postgres\_host](#output\_postgres\_host) | The hostname of the PostgreSQL server |
| <a name="output_postgres_password"></a> [postgres\_password](#output\_postgres\_password) | The password for PostgreSQL database access |
| <a name="output_postgres_username"></a> [postgres\_username](#output\_postgres\_username) | The username for PostgreSQL database access |
| <a name="output_public_ip_jumpbox"></a> [public\_ip\_jumpbox](#output\_public\_ip\_jumpbox) | The private IP address of the jumpbox |
| <a name="output_redis_data_volume_id"></a> [redis\_data\_volume\_id](#output\_redis\_data\_volume\_id) | The volume ID of the Redis data volume. |
| <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name) | The resource group where resources were deployed |
| <a name="output_service_account_configs"></a> [service\_account\_configs](#output\_service\_account\_configs) | The Azure identity configs |
| <a name="output_vnet_name"></a> [vnet\_name](#output\_vnet\_name) | The name of the virtual network |
| <a name="output_vpc_cidr"></a> [vpc\_cidr](#output\_vpc\_cidr) | The CIDR block of the VPC |

<!-- END_TF_DOCS -->