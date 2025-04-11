resource "azurerm_network_security_group" "hub_nsg" {
  name                = "nsg-hub-iis-core-uks-001"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = local.tags

  # Inbound
  security_rule {
    name                         = "allow-icmp-inbound"
    priority                     = 100
    direction                    = "Inbound"
    access                       = "Allow"
    protocol                     = "Icmp"
    source_port_range            = "*"
    destination_port_range       = "*"
    source_address_prefixes      = ["192.168.0.4", "192.168.0.20"]
    destination_address_prefixes = [var.iis_nic_private_ip]
  }

  security_rule {
    name                         = "allow-rdp-inbound"
    priority                     = 110
    direction                    = "Inbound"
    access                       = "Allow"
    protocol                     = "Tcp"
    source_port_range            = "*"
    destination_port_range       = "3389"
    source_address_prefixes      = [data.http.my_public_ip.response_body]
    destination_address_prefixes = [var.iis_nic_private_ip]
  }

  security_rule {
    name                         = "allow-http-inbound"
    priority                     = 120
    direction                    = "Inbound"
    access                       = "Allow"
    protocol                     = "Tcp"
    source_port_range            = "*"
    destination_port_range       = "80"
    source_address_prefixes      = ["192.168.0.4", "192.168.0.20"]
    destination_address_prefixes = [var.iis_nic_private_ip]
  }

  # Outbound
  security_rule {
    name                         = "allow-icmp-outbound"
    priority                     = 105
    direction                    = "Outbound"
    access                       = "Allow"
    protocol                     = "Icmp"
    source_port_range            = "*"
    destination_port_range       = "*"
    source_address_prefixes      = [var.iis_nic_private_ip]
    destination_address_prefixes = ["192.168.0.4", "192.168.0.20"]
  }

  depends_on = [data.http.my_public_ip]
}

resource "azurerm_network_security_group" "spoke_nsg" {
  name                = "nsg-spoke-backend-uks-001"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = local.tags

  # Inbound
  security_rule {
    name                         = "allow-icmp-inbound"
    priority                     = 100
    direction                    = "Inbound"
    access                       = "Allow"
    protocol                     = "Icmp"
    source_port_range            = "*"
    destination_port_range       = "*"
    source_address_prefixes      = [var.iis_nic_private_ip]
    destination_address_prefixes = ["192.168.0.4", "192.168.0.20"]
  }

  security_rule {
    name                         = "allow-rdp-inbound"
    priority                     = 110
    direction                    = "Inbound"
    access                       = "Allow"
    protocol                     = "Tcp"
    source_port_range            = "*"
    destination_port_range       = "3389"
    source_address_prefixes      = [data.http.my_public_ip.response_body]
    destination_address_prefixes = ["192.168.0.4", "192.168.0.20"]
  }

  # Outbound
  security_rule {
    name                         = "allow-icmp-outbound"
    priority                     = 105
    direction                    = "Outbound"
    access                       = "Allow"
    protocol                     = "Icmp"
    source_port_range            = "*"
    destination_port_range       = "*"
    source_address_prefixes      = ["192.168.0.4", "192.168.0.20"]
    destination_address_prefixes = [var.iis_nic_private_ip]
  }

  security_rule {
    name                         = "allow-http-outbound"
    priority                     = 115
    direction                    = "Outbound"
    access                       = "Allow"
    protocol                     = "Tcp"
    source_port_range            = "*"
    destination_port_range       = "80"
    source_address_prefixes      = ["192.168.0.4", "192.168.0.20"]
    destination_address_prefixes = [var.iis_nic_private_ip]
  }

  depends_on = [data.http.my_public_ip]
}