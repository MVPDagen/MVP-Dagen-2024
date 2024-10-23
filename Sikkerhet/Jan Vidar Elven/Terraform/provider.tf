terraform {
    required_version = ">= 1.9"
    required_providers {
    azurerm = {
        source  = "hashicorp/azurerm"
        version = "~> 4.5"
        }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0"
    }    
    }
}

variable "subscription_id" {
  sensitive = true  
}
variable "tenant_id" {
  sensitive = true    
}

provider "azurerm" {
    features {
    virtual_machine {
        delete_os_disk_on_deletion = true
    }
    }
    subscription_id = var.subscription_id
}

provider "azuread" {
  tenant_id = var.tenant_id
}
