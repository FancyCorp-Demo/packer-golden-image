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




# TODO: Create AWS Build VPC
#
# Packer can then select it with vpc_filter and subnet_filter
# https://developer.hashicorp.com/packer/plugins/builders/amazon/ebs#vpc_filter
# https://developer.hashicorp.com/packer/plugins/builders/amazon/ebs#subnet_filter
