resource "azurerm_network_security_group" "hub_nsg" {
  name                = "nsg-hub-uks-001"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = local.tags

  # Inbound
  security_rule {
    name                         = "allow-rdp-inbound"
    priority                     = 100
    direction                    = "Inbound"
    access                       = "Allow"
    protocol                     = "Tcp"
    source_port_range            = "*"
    destination_port_range       = "3389"
    source_address_prefixes      = [data.http.my_public_ip.response_body]
    destination_address_prefixes = [var.iis_nic_private_ip]
  }

  security_rule {
    name                   = "allow-http-inbound"
    priority               = 110
    direction              = "Inbound"
    access                 = "Allow"
    protocol               = "Tcp"
    source_port_range      = "*"
    destination_port_range = "80"
    source_address_prefixes = [
      local.spoke_vms["snet-sql-backend"].private_ip,
      local.spoke_vms["snet-integration-backend"].private_ip,
    ]
    destination_address_prefixes = [var.iis_nic_private_ip]
  }
  depends_on = [data.http.my_public_ip]
}

resource "azurerm_network_security_group" "spoke_nsg" {
  name                = "nsg-spokes-uks-001"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = local.tags

  # Inbound
  security_rule {
    name                    = "allow-rdp-inbound"
    priority                = 100
    direction               = "Inbound"
    access                  = "Allow"
    protocol                = "Tcp"
    source_port_range       = "*"
    destination_port_range  = "3389"
    source_address_prefixes = [data.http.my_public_ip.response_body]
    destination_address_prefixes = [
      local.spoke_vms["snet-sql-backend"].private_ip,
      local.spoke_vms["snet-integration-backend"].private_ip,
      local.spoke_vms["snet-hsm-backend"].private_ip,
    ]
  }

  # Outbound
  security_rule {
    name                   = "allow-http-outbound"
    priority               = 115
    direction              = "Outbound"
    access                 = "Allow"
    protocol               = "Tcp"
    source_port_range      = "*"
    destination_port_range = "80"
    source_address_prefixes = [
      local.spoke_vms["snet-sql-backend"].private_ip,
      local.spoke_vms["snet-integration-backend"].private_ip,
    ]
    destination_address_prefixes = [var.iis_nic_private_ip]
  }

  depends_on = [data.http.my_public_ip]
}