# Authenticated user identity's object ID for RBAC
data "azurerm_client_config" "current" {}

data "http" "myip" {
  url = "https://ifconfig.io/"
}