variable "subscription_id" {
  type    = string
  default = null
}

variable "tenant_id" {
  type    = string
  default = null
}

variable "iis_nic_private_ip" {
  type        = string
  description = "IIS server private IP address declared in terraform.tfvars"
  default     = "192.168.5.4"
}

variable "iis_admin_uname" {
  type        = string
  description = "Admin username for IIS server declared in terraform.tfvars"
  default     = null
  sensitive   = true
}

variable "iis_admin_pwd" {
  type        = string
  description = "Admin password for IIS server declared in terraform.tfvars"
  default     = null
  sensitive   = true
}


variable "spokevm_admin_uname" {
  type        = string
  description = "Admin username for spoke servers eclared in terraform.tfvars"
  default     = null
  sensitive   = true
}

variable "spokevm_admin_pwd" {
  type        = string
  description = "Admin password for spoke servers declared in terraform.tfvars"
  default     = null
  sensitive   = true
}
