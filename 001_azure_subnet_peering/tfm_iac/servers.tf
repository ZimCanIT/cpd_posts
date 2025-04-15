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

resource "azurerm_virtual_machine_extension" "enable_iis" {
  name                       = "iis-ext-001"
  virtual_machine_id         = azurerm_windows_virtual_machine.iis_srv.id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.10"
  auto_upgrade_minor_version = true
  tags                       = local.tags

  settings = <<SETTINGS
    {
       "commandToExecute": "powershell -Command \"Install-WindowsFeature -Name Web-Server -IncludeManagementTools\""
    }
  SETTINGS
}

resource "azurerm_windows_virtual_machine" "spoke_vms" {
  for_each = local.spoke_vms

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