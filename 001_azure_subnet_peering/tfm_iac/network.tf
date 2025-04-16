resource "azurerm_resource_group" "rg" {
  name     = "RG-ZIMCANIT-SNETPEERING-DMO-UKS-001"
  location = "uksouth"
  tags     = local.tags
}

module "hub_vnet" {
  source              = "Azure/avm-res-network-virtualnetwork/azurerm"
  name                = "VNET-HUB-UKS-001"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = [local.hub_vnet_address]
  subnets             = local.hub_vnet_subnets
  tags                = local.tags
}

module "spoke_vnet" {
  source              = "Azure/avm-res-network-virtualnetwork/azurerm"
  name                = "VNET-SPOKE-UKS-001"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = [local.spoke_vnet_address]
  subnets             = local.spoke_vnet_subnets
  tags                = local.tags
}

resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name                                   = "VNET-HUB-UKS-001--to--VNET-SPOKE-UKS-001"
  resource_group_name                    = azurerm_resource_group.rg.name
  virtual_network_name                   = module.hub_vnet.name
  remote_virtual_network_id              = module.spoke_vnet.resource_id
  allow_virtual_network_access           = true
  allow_forwarded_traffic                = false
  allow_gateway_transit                  = false
  peer_complete_virtual_networks_enabled = false
  use_remote_gateways                    = false

  local_subnet_names = [
    module.hub_vnet.subnets["snet-iiscore-frontend"].name
  ]

  remote_subnet_names = [
    module.spoke_vnet.subnets["snet-sql-backend"].name,
    module.spoke_vnet.subnets["snet-integration-backend"].name
  ]
}

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                                   = "VNET-SPOKE-UKS-001--to--VNET-HUB-UKS-001"
  resource_group_name                    = azurerm_resource_group.rg.name
  virtual_network_name                   = module.spoke_vnet.name
  remote_virtual_network_id              = module.hub_vnet.resource_id
  allow_virtual_network_access           = true
  allow_forwarded_traffic                = false
  allow_gateway_transit                  = false
  peer_complete_virtual_networks_enabled = false
  use_remote_gateways                    = false

  local_subnet_names = [
    module.spoke_vnet.subnets["snet-sql-backend"].name,
    module.spoke_vnet.subnets["snet-integration-backend"].name
  ]

  remote_subnet_names = [
    module.hub_vnet.subnets["snet-iiscore-frontend"].name
  ]
}

resource "azurerm_public_ip" "iis_pip" {
  name                = "pip-vmiiscore-uks-001"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
  sku_tier            = "Regional"
  tags                = local.tags
}

resource "azurerm_public_ip" "spoke_pips" {
  for_each = local.spoke_vms

  name                = "pip-${each.value.vm_name}-uks-001"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
  sku_tier            = "Regional"
  tags                = local.tags
}

resource "azurerm_network_interface" "iis_nic" {
  name                = "nic-vmiiscore-uks-001"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = local.tags

  ip_configuration {
    name                          = "ipconf"
    subnet_id                     = module.hub_vnet.subnets["snet-iiscore-frontend"].resource_id
    private_ip_address_allocation = "Static"
    private_ip_address_version    = "IPv4"
    private_ip_address            = var.iis_nic_private_ip
    public_ip_address_id          = azurerm_public_ip.iis_pip.id
  }
}

resource "azurerm_network_interface" "spoke_nics" {
  for_each            = local.spoke_vms
  name                = "nic-${each.value.vm_name}-uks-001"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.tags

  ip_configuration {
    name                          = "ipconf"
    subnet_id                     = module.spoke_vnet.subnets[each.key].resource_id
    private_ip_address_allocation = "Static"
    private_ip_address            = each.value.private_ip
    private_ip_address_version    = "IPv4"
    public_ip_address_id          = azurerm_public_ip.spoke_pips[each.key].id
  }
}