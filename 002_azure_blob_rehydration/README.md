# Blob Rehydrate

Purpose: Showcases the Azure Storage Account blob rehydration process using Terraform and Azure CLI.

## Prerequisites

Ensure you have the following before getting started:

* Access to an Azure subscription with permission to assign RBAC roles.
* [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) installed (used for authentication with Terraform and script execution).
* [Git CLI](https://git-scm.com/downloads) installed (used to clone this repository).
* [Terraform](https://developer.hashicorp.com/terraform/downloads) installed (used to deploy Azure infrastructure).

## Deployment

* Authenticate to azure and set the subscription context
  * `az login`
  * `az account set -s <your subscription id>`
  * `az account show`
* Within directory `tfm_iac\` run terraform commands workflow:
  * `terraform init`
  * `terraform plan -out storage_infra.tfplan` 
  * `terraform apply -auto-approve ".\storage_infra.tfplan"`
* Rehdrate uploaded blob objects within directory: `002_azure_blob_rehydration\`:
  * `.\blob_rehydrate.ps1 -accountName <enter storage account name> -containerName <enter storage account container name>`

## Resource destruction 

* Within directory `tfm_iac\` run the terraform command: `terraform destroy -auto-approve`
* Logout of azure: `az logout`

## Docs

* [Azure cli command: az storage blob set-tier](https://learn.microsoft.com/en-us/cli/azure/storage/blob?view=azure-cli-latest#az-storage-blob-set-tier)
* [Blob rehydration from the archive tier](https://learn.microsoft.com/en-us/azure/storage/blobs/archive-rehydrate-overview)
* [Azure storage explorer](https://azure.microsoft.com/en-us/products/storage/storage-explorer)