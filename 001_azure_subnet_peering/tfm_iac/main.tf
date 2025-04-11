resource "azurerm_resource_group" "rg" {
  name     = "rg-zimcanit-microsegmentation-dmo-uks-001"
  location = "uksouth"
  tags     = local.tags
}

# https://registry.terraform.io/modules/Azure/avm-res-network-virtualnetwork/azurerm/latest
module "hub_vnet" {
  source              = "Azure/avm-res-network-virtualnetwork/azurerm"
  name                = "vnet-hub-iiscore-uks-001"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = [local.hub_vnet_address]
  subnets             = local.hub_vnet_subnets
  tags                = local.tags
}

module "spoke_vnet" {
  source              = "Azure/avm-res-network-virtualnetwork/azurerm"
  name                = "vnet-spoke-backup-uks-001"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = [local.spoke_vnet_address]
  subnets             = local.spoke_vnet_subnets
  tags                = local.tags

  peerings = {
    spoketohub = {
      name                               = "vnet-spoke-backup-uks-001--to--vnet-hub-iiscore-uks-001"
      remote_virtual_network_resource_id = module.hub_vnet.resource_id
      allow_forwarded_traffic            = false
      allow_gateway_transit              = false
      allow_virtual_network_access       = true
      peer_complete_vnets                = false
      local_peered_subnets = [
        {
          subnet_name = "sql-server-backend-001"
        },
        {
          subnet_name = "cloud-backup-001"
        }
      ]
      remote_peered_subnets = [
        {
          subnet_name = module.hub_vnet.subnets["iis-core-frontend-001"].name
        }
      ]

      create_reverse_peering               = true
      reverse_name                         = "vnet-hub-iiscore-uks-001--to--vnet-spoke-backup-uks-001"
      reverse_allow_forwarded_traffic      = false
      reverse_allow_gateway_transit        = false
      reverse_allow_virtual_network_access = true
      reverse_peer_complete_vnets          = false
      reverse_local_peered_subnets = [
        {
          subnet_name = module.hub_vnet.subnets["iis-core-frontend-001"].name
        }
      ]
      reverse_remote_peered_subnets = [
        {
          subnet_name = "sql-server-backend-001"
        },
        {
          subnet_name = "cloud-backup-001"
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

# IIS server public IP
resource "azurerm_public_ip" "iis_pip" {
  name                = "pip-vmiiscore-uks-001"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
  sku_tier            = "Regional"
  tags                = local.tags
}

# IIS server nic
resource "azurerm_network_interface" "iis_nic" {
  name                = "nic-vmiiscore-uks-001"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = local.tags

  ip_configuration {
    name                          = "ipconf"
    subnet_id                     = module.hub_vnet.subnets["iis-core-frontend-001"].resource_id
    private_ip_address_allocation = "Static"
    private_ip_address_version    = "IPv4"
    private_ip_address            = var.iis_nic_private_ip
    public_ip_address_id          = azurerm_public_ip.iis_pip.id
  }
}

# IIS server
resource "azurerm_windows_virtual_machine" "iis_srv" {
  name                       = "vmiiscore-uks-001"
  computer_name              = "vmiiscore"
  resource_group_name        = azurerm_resource_group.rg.name
  location                   = azurerm_resource_group.rg.location
  size                       = "Standard_B2ms"
  admin_username             = var.iis_admin_uname
  admin_password             = var.iis_admin_pwd
  tags                       = local.tags
  allow_extension_operations = true
  provision_vm_agent         = true
  custom_data                = base64encode(file("${path.module}/enable_icmpv4.ps1"))



  network_interface_ids = [
    azurerm_network_interface.iis_nic.id,
  ]

  os_disk {
    name                 = "osdisk-vmiiscore-001"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }
}

# IIS Virtual Machine Extension
resource "azurerm_virtual_machine_extension" "iis-vm-extension" {
  name                 = "iis-ext-001"
  virtual_machine_id   = azurerm_windows_virtual_machine.iis_srv.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.9"
  tags                 = local.tags

  settings = <<SETTINGS
    { 
      "commandToExecute": "powershell Install-WindowsFeature -name Web-Server -IncludeManagementTools;"
    } 
  SETTINGS
}


# Spoke VM public IPs
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


# Spoke VM nics
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

# Deploy Spoke servers
resource "azurerm_windows_virtual_machine" "spoke_vms" {
  for_each                   = local.spoke_vms
  name                       = "${each.value.vm_name}-uks-001"
  computer_name              = each.value.vm_name
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  size                       = "Standard_B2ms"
  admin_username             = var.spokevm_admin_uname
  admin_password             = var.spokevm_admin_pwd
  tags                       = local.tags
  allow_extension_operations = true
  provision_vm_agent         = true
  custom_data                = base64encode(file("${path.module}/enable_icmpv4.ps1"))

  network_interface_ids = [
    azurerm_network_interface.spoke_nics[each.key].id,
  ]

  os_disk {
    name                 = "osdisk-${each.value.vm_name}-001"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }
}


