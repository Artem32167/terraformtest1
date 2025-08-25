variable "resource_group_name" {
  type        = string
  description = "Name of the Resource Group"
}

variable "location" {
  type        = string
  description = "Azure region"
  default     = "westeurope"
}

variable "vnet_name" {
  type        = string
  description = "Name of Vnet"
}

variable "subnet_name" {
  type        = string
  description = "name of subnet"
}

variable "nsg_name" {
  type        = string
  description = "name of nsg"
}

variable "vm-name" {
  type        = string
  description = "name of VM"
}

variable "vm-pip-name" {
  type        = string
  description = "name o PIP"
}

variable "nic-name" {
  type        = string
  description = "name o NIC"
}

variable "tags" {
  type = map(string)
  default = {
    environment = "dev"
    owner       = "Artsemi"
  }
}

variable "enable_monitoring" {
  type    = bool
  default = true
}

variable "additional_tags" {
  type    = map(string)
  default = {}
}

variable "environments" {
  type = map(string)
  default = {
    dev   = "westeurope"
    stage = "northeurope"
    prod  = "uksouth"
    test  = "westeurope"
  }
}

variable "rg_names" {
  type    = list(string)
  default = ["dev", "stage", "prod", "test"]
}

variable "location2" {
  type    = string
  default = "westeurope"
}

variable "pip_generation" {
  type    = string
  default = "v1"
}

variable "protect_prod" {
  type    = bool
  default = true
}

variable "rg_for_preventdestroy" {
  type = string
}

# Bump this to force a VM replacement (e.g., after updating base image or hardening)
variable "image_release" {
  type        = string
  default     = "2025-08-13.1"
  description = "Change value to trigger VM replacement"
}

variable "nsg_rules" {
  type = list(object({
    name     = string
    port     = number
    priority = number
  }))

  default = [
    {
      name     = "AllowHTTP"
      port     = 80
      priority = 100
    },
    {
      name     = "AllowHTTPS"
      port     = 443
      priority = 110
    },
    {
      name     = "AllowSSH"
      port     = 22
      priority = 120
    }
  ]
}

variable "env_name" {
  description = "Environment name (e.g., dev, prod)"
  default     = "prod"
  type        = string
}

variable "kv_name" {
  type        = string
  description = "Key Vault name (must be globally unique)"
}

variable "sql_admin_password" {
  type        = string
  description = "SQL admin password (provided via CLI or pipeline secret)"
  default     = "UGiSqN029y5jtgcOHHteB9Zh"
  sensitive   = true
}

variable "manage_secret_in_tf" {
  type        = bool
  description = "Whether Terraform should create the secret in Key Vault"
  default     = true
}