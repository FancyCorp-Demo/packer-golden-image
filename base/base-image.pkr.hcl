packer {
  required_plugins {
    amazon = {
      version = ">= 1.0.4"
      source  = "github.com/hashicorp/amazon"
    }

    azure = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/azure"
    }
  }
}

local "suffix" {
  expression = formatdate("YYYY-MM-DD-hh-mm-ss", timestamp())
}

source "azure-arm" "ubuntu" {
  use_azure_cli_auth = true

  os_type         = "Linux"
  image_publisher = "canonical"
  image_offer     = "0001-com-ubuntu-server-focal"
  image_sku       = "20_04-lts-gen2"

  vm_size = "Standard_B1ls"

  build_resource_group_name = "strawb-packerdemo"

  managed_image_resource_group_name = "strawb-packerdemo"
  managed_image_name                = "strawbtest-demo-base-v0.1.0-${local.suffix}"

  ssh_username = "ubuntu"
}

source "amazon-ebs" "ubuntu" {
  ami_name = "strawbtest/demo/base/v0.1.0/${local.suffix}"

  instance_type = "t2.micro"

  source_ami_filter {
    filters = {
      name                = "ubuntu/images/*ubuntu-focal-20.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }

    most_recent = true
    owners      = ["099720109477"]
  }

  # region to build in
  region = "eu-west-2"

  # region to deploy to
  ami_regions = [
    "eu-west-1",
    "eu-west-2",
  ]

  # And accounts allowed to use it
  ami_users = [
    "711129375688", # se_demos_dev
    "564784738291", # sandbox
  ]

  tags = {
    Name    = "StrawbTest"
    Owner   = "lucy.davinhart@hashicorp.com"
    Purpose = "Base Image for Packer Demo"
    TTL     = "24h"
    Packer  = true
    Source  = "https://github.com/hashi-strawb/packer-golden-image/tree/main/base/"
  }

  ssh_username = "ubuntu"
}

build {
  name = "provision"

  sources = [
    "source.amazon-ebs.ubuntu",
    "source.azure-arm.ubuntu",
  ]

  provisioner "shell" {
    script = "provision.sh"
  }

  hcp_packer_registry {
    bucket_name = "base-image"

    description = <<EOT
Golden Base Image
    EOT

    bucket_labels = {
      "owner" = "platform-team"
    }

    build_labels = {
      "os"             = "Ubuntu"
      "ubuntu-version" = "Focal 20.04"
      "version"        = "v0.1.0"
    }
  }
}
