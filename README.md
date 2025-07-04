=======
# Datafold Azure module

This repository provisions resources on Azure, preparing them for a deployment of the
application on an AKS cluster.

## About this module

## Prerequisites

* An Azure subscription, preferably a new isolated one.
* Terraform >= 1.4.6
* A customer contract with Datafold
  * The application does not work without credentials supplied by sales
* Access to our public helm-charts repository

This deployment will create the following resources:

* Azure VPC
* Azure subnet
* Azure blob storage for clickhouse backups
* Azure Application Gateway
* Azure bastion
* Azure jump vm
* Azure certificate, unless preregistered and provided
* Three Azure cloud volumes for local data storage
* Azure Postgres database
* An AKS cluster
* Service accounts for the AKS cluster to perform actions outside of its cluster boundary:
  * Provisioning existing volumes
  * Updating application gateway to point to specific pods in the cluster
  * Rescaling the nodegroup between 1-2 nodes

## Negative scope

* This module will not provision DNS names in your zone.

## How to use this module

* See the example for a potential setup, which has dependencies on our helm-charts

Create the bucket and dynamodb table for terraform state file:

* Use the files in `bootstrap` to create a terraform state bucket and a dynamodb lock table. Example provided is for AWS
* Run `./run_bootstrap.sh` to create them. Enter the deployment_name when the question is asked.
  * The `deployment_name` is important. This is used for the k8s namespace and datadog unified logging tags and other places.
  * Suggestion: `company-datafold`
* Transfer the name of that bucket and table into the `backend.hcl` (symlinked into both infra and application)
* Set the `target_account_profile` and `region` where the bucket / table are stored.
* `backend.hcl` is only about where the terraform state file is located.

The example directory contains a single deployment example, which cleanly separates the 
underlying runtime infra from the application deployment into kubernetes. Some specific
elements from the `infra` directory are copied and encrypted into the `application` directory.

Setting up the infrastructure:

* It is easiest if you have full admin access in the target subscription.
* Pre-create the certificate you want to use on the application gateway and validate it in your DNS.
* Pre-create a symmetric encryption key that is used to encrypt/decrypt secrets of this deployment.
  * Use the alias instead of the `mrk` link. Put that into `locals.tf`
* Refer to that certificate in main.tf using it's domain name: (Replace "datafold.acme.com")
* Change the settings in locals.tf (the versions in infra and application are sym-linked)
  * provider_region = which region you want to deploy in.
  * resource_group_name = The resource group in which to deploy.
  * kms_profile = Can be the same profile, unless you want the encryption key elsewhere.
  * kms_key = A pre-created symmetric KMS key. It's only purpose is for encryption/decryption of deployment secrets.
  * deployment_name = The name of the deployment, used in kubernetes namespace, container naming and datadog "deployment" Unified Tag)
  * azure_tenant_id = The tenant ID where to deploy.
  * azure_subscription_id = The ID of the subscription to deploy in.
* Run `terraform init -backend-config=../backend.hcl` in both application and infra directory.
* Our team will reach out to give you two secrets files:
  * `secrets.yaml` goes into the `application` directory.
  * Encrypt both files with sops and call both `secrets.yaml`
* Run `terraform apply` in `infra` directory. This should complete ok. 
  * Check in the console if you see the load balancer, the EKS cluster, etc.
* Run `terraform apply` in `application` directory.
  * Check the settings made in the `main.tf` file. Maybe you want to set "datadog.install" to `false`. 
  * Check with your favourite kubernetes tool if you see the namespace and several datafold pods running there.

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

Establish a shell into the `<deployment>-dfshell` container. 
It is likely that the scheduler and server containers are crashing in a loop.

All we need to is to run these commands:

1. `./manage.py clickhouse create-tables`
2. `./manage.py database create-or-upgrade`
3. `./manage.py installation set-new-deployment-params`

Now all containers should be up and running.

<!-- BEGIN_TF_DOCS -->
