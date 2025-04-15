resource "azurerm_resource_group" "rg" {
  name     = "RG-ZIMCANIT-SNETPEERING-DMO-UKS-001"
  location = "uksouth"
  tags     = local.tags
}

# https://registry.terraform.io/modules/Azure/avm-res-network-virtualnetwork/azurerm/latest
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

  peerings = {
    spoketohub = {
      name                               = "vnet-spoke-uks-001--to--vnet-hub-uks-001"
      remote_virtual_network_resource_id = module.hub_vnet.resource_id
      allow_forwarded_traffic            = false
      allow_gateway_transit              = false
      allow_virtual_network_access       = true
      peer_complete_vnets                = false
      local_peered_subnets = [
        {
          subnet_name = "snet-sql-backend"
        },
        {
          subnet_name = "snet-integration-backend"
        }
      ]
      remote_peered_subnets = [
        {
          subnet_name = module.hub_vnet.subnets["snet-iiscore-frontend"].name
        }
      ]

      create_reverse_peering               = true
      reverse_name                         = "vnet-hub-uks-001--to--vnet-spoke-uks-001"
      reverse_allow_forwarded_traffic      = false
      reverse_allow_gateway_transit        = false
      reverse_allow_virtual_network_access = true
      reverse_peer_complete_vnets          = false
      reverse_local_peered_subnets = [
        {
          subnet_name = module.hub_vnet.subnets["snet-iiscore-frontend"].name
        }
      ]
      reverse_remote_peered_subnets = [
        {
          subnet_name = "snet-sql-backend"
        },
        {
          subnet_name = "snet-integration-backend"
        }
      ]
    }
  }

  depends_on = [
    azurerm_resource_group.rg,
    module.hub_vnet,
    azurerm_network_security_group.spoke_nsg
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