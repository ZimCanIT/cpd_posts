output "storage_account_name" {
  description = "The name of the deployed storage account to be referenced in the script: 'blob_rehydrate.ps1'"
  value       = azurerm_storage_account.demo_storage.name
}

output "storage_account_cotainer_name" {
  description = "The name of the deployed storage account container to be referenced in the script: 'blob_rehydrate.ps1'"
  value       = azurerm_storage_container.demo_container.name
}