locals {
  tags = {
    Application          = "Subnet peering demo"
    Owner                = "ZimCanIT"
    Criticality          = "T-3"
    Environment          = "Development"
    "Operational Status" = "Active"
    "Hours of Operation" = "24x7"
    "Business Unit"      = "IT"
  }

  hub_vnet_subnet_names = ["iis-core-frontend-001", "analytics-platform-001", "syslog-servers-001"]
  hub_vnet_address      = "192.168.5.0/24"

  hub_vnet_subnets = {
    for i, subnet_name in local.hub_vnet_subnet_names :
    subnet_name => {
      name           = subnet_name
      address_prefix = cidrsubnet(local.hub_vnet_address, 4, i)
      network_security_group = {
        id = azurerm_network_security_group.hub_nsg.id
      }
    }
  }

  spoke_vnet_subnet_names = ["sql-server-backend-001", "cloud-backup-001", "biz-reporting-001"]
  spoke_vnet_address      = "192.168.0.0/24"

  spoke_vnet_subnets = {
    for i, subnet_name in local.spoke_vnet_subnet_names :
    subnet_name => {
      name           = subnet_name
      address_prefix = cidrsubnet(local.spoke_vnet_address, 4, i)
      network_security_group = {
        id = azurerm_network_security_group.spoke_nsg.id
      }
    }
  }

  spoke_vms = {
    "sql-server-backend-001" = {
      vm_name    = "vmsqlsrv"
      private_ip = "192.168.0.4"
    }
    "cloud-backup-001" = {
      vm_name    = "vmcloudbackup"
      private_ip = "192.168.0.20"
    }
    "biz-reporting-001" = {
      vm_name    = "vmbizreports"
      private_ip = "192.168.0.36"
    }
  }
}