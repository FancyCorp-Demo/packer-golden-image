terraform {
  cloud {
    organization = "hashi_strawb_testing"

    workspaces {
      name = "azure-packer-resources"
    }
  }
}

variable "resource_group_name" {
  default = "strawb-packerdemo"
}

variable "location" {
  default = "UK South"
}

variable "resource_group_tags" {
  default = {
    Terraform = "true"
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.resource_group_tags
}
