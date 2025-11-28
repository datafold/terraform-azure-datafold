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
