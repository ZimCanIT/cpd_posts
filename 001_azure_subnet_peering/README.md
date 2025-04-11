# 001 Azure Subnet Peering

## Architecture

* IIS server can ping backend vms and access the sql server on port 1433
* Backend vms can ping iis server and that's it 
* Imagine that the spoke vms subnet: `"reporting-cluster-001"` does not need to have access to the iis frontend web server

## Deployment 

* Enable Azure cli Microsoft.Network resource provider
  * `az feature register --namespace Microsoft.Network --name AllowMultiplePeeringLinksBetweenVnets`
  * `az feature show --name AllowMultiplePeeringLinksBetweenVnets --namespace Microsoft.Network --query 'properties.state' -o tsv`  

## Docs

* [Terraform Provider for Azure Resource Manager Rest API](https://github.com/Azure/terraform-provider-azapi/tree/v2.3.0?tab=readme-ov-file)
* [AzAPI Provider](https://registry.terraform.io/providers/Azure/azapi/latest/docs)
* [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
* [Azure Virtual Network Module](https://github.com/Azure/terraform-azurerm-avm-res-network-virtualnetwork?tab=readme-ov-file)
* [How to configure subnet peering](https://learn.microsoft.com/en-us/azure/virtual-network/how-to-configure-subnet-peering)
* [Microsoft.Network virtualNetworks/virtualNetworkPeerings](https://learn.microsoft.com/en-us/azure/templates/microsoft.network/virtualnetworks/virtualnetworkpeerings?pivots=deployment-language-terraform)
* [Terraform Resource Modules](https://azure.github.io/Azure-Verified-Modules/indexes/terraform/tf-resource-modules/)
* [avm-res-network-virtualnetwork](https://registry.terraform.io/modules/Azure/avm-res-network-virtualnetwork/azurerm/latest)