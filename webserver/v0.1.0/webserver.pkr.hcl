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

data "hcp-packer-iteration" "base-image" {
  bucket_name = "base-image"
  channel     = "production"
}


data "hcp-packer-image" "azure-base-image" {
  bucket_name    = "base-image"
  iteration_id   = data.hcp-packer-iteration.base-image.id
  cloud_provider = "azure"
  region         = "uksouth"
}
source "azure-arm" "base" {
  use_azure_cli_auth = true

  os_type                                  = data.hcp-packer-image.azure-base-image.labels["os_type"]
  custom_managed_image_name                = data.hcp-packer-image.azure-base-image.labels["managed_image_name"]
  custom_managed_image_resource_group_name = data.hcp-packer-image.azure-base-image.labels["managed_image_resourcegroup_name"]

  vm_size = "Standard_B1ls"

  build_resource_group_name = "strawb-packerdemo"

  managed_image_resource_group_name = "strawb-packerdemo"
  managed_image_name                = "strawbtest-demo-webserver-from-base-v0.1.0-${local.suffix}"

  ssh_username = "ubuntu"
}


data "hcp-packer-image" "aws-base-image" {
  bucket_name    = "base-image"
  iteration_id   = data.hcp-packer-iteration.base-image.id
  cloud_provider = "aws"
  region         = "eu-west-2"
}
source "amazon-ebs" "base" {
  ami_name = "strawbtest/demo/webserver-from-base/v0.1.0/${local.suffix}"

  instance_type = "t2.micro"

  # region to build in
  region = "eu-west-2"

  # Source AMI from HCP Packer
  source_ami = data.hcp-packer-image.aws-base-image.id

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
    Purpose = "Dummy Webserver for TFC Demo"
    TTL     = "30d"
    Packer  = true
    Source  = "https://github.com/hashi-strawb/packer-golden-image/tree/main/webserver/v0.1.0/"
  }

  # Tell AWS to deprecate the image after 30 days
  deprecate_at = timeadd(timestamp(), "720h")


  ssh_username = "ubuntu"
}

build {
  name = "webserver"

  sources = [
    "source.amazon-ebs.base",
    "source.azure-arm.base",
  ]

  provisioner "file" {
    source      = "index.html"
    destination = "/home/ubuntu/index.html"
  }

  provisioner "shell" {
    inline = [
      "sudo apt-get -yq update",
      "sudo apt-get -yq install nginx",
      "sudo mv /home/ubuntu/index.html /var/www/html/index.html",
    ]
  }

  hcp_packer_registry {
    bucket_name = "webserver"

    description = <<EOT
Dummy webserver for demonstration purposes
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
