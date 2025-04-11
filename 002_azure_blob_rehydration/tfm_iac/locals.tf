locals {
  blob_directories = [
    "dir01/subdir001",
    "dir02/subdir002/subdir0002",
    "dir03"
  ]

  tags = {
    Application = "Blob rehydration demo"
    Owner       = "ZimCanIT"
    Criticality = "T-3"
    Environment = "Development"
  }
}