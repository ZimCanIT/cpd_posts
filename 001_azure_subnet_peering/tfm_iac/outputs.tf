output "iis_server_private_ip" {
  description = "IIS server private IP address."
  value       = azurerm_network_interface.iis_nic.private_ip_address
}

output "my_ip" {
  description = "My public IP address."
  value       = data.http.my_public_ip.response_body
}