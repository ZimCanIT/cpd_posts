resource "azurerm_resource_group" "rg" {
  name     = "rg-zimcanit-blob-rehydrate-uks-001"
  location = "uksouth"
  tags     = local.tags
}

resource "random_string" "unique" {
  length  = 7
  lower   = true
  upper   = false
  numeric = true
  special = false
}

resource "azurerm_storage_account" "demo_storage" {
  name                            = "zimcanitrehydrate${random_string.unique.result}"
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  account_tier                    = "Standard"
  account_kind                    = "StorageV2"
  account_replication_type        = "LRS"
  access_tier                     = "Hot"
  https_traffic_only_enabled      = true
  min_tls_version                 = "TLS1_2"
  shared_access_key_enabled       = true
  allow_nested_items_to_be_public = true
  public_network_access_enabled   = true
  tags                            = local.tags

  network_rules {
    default_action = "Allow"
    ip_rules       = [data.http.myip.response_body]
    bypass         = ["AzureServices"]
  }
}

resource "azurerm_role_assignment" "blob_data_contributor" {
  principal_id         = data.azurerm_client_config.current.object_id
  role_definition_name = "Storage Blob Data Contributor"
  scope                = azurerm_storage_account.demo_storage.id

  depends_on = [
    azurerm_storage_account.demo_storage,
  ]
}
resource "azurerm_storage_container" "demo_container" {
  name                  = "demo-container-${random_string.unique.result}"
  storage_account_id    = azurerm_storage_account.demo_storage.id
  container_access_type = "private"

  metadata = {
    purpose               = "blob_rehydration_demo"
    owner                 = "zimcanit"
    criticality           = "t3_dev"
    "data_classification" = "public"
  }

  depends_on = [
    azurerm_storage_account.demo_storage,
  ]
}

resource "azurerm_storage_blob" "demo_blob" {
  for_each = toset(local.blob_directories)

  name                   = "${each.key}/demo_blob_file.txt"
  storage_account_name   = azurerm_storage_account.demo_storage.name
  storage_container_name = azurerm_storage_container.demo_container.name
  type                   = "Block"
  source                 = "${path.module}/../demo_blob_file.txt"
  access_tier            = "Archive"

  metadata = {
    owner                 = "zimcanit"
    criticality           = "t3_dev"
    "data_classification" = "public"
    "file_type"           = "_.txt"
    "upload_mechanism"    = "terraform"
  }

  depends_on = [
    azurerm_storage_account.demo_storage,
    azurerm_storage_container.demo_container,
  ]
}

