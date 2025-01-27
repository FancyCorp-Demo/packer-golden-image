packer {
  required_plugins {
    amazon = {
      version = ">= 1.1.0" # for SSH stuff https://github.com/hashicorp/packer-plugin-amazon/releases/tag/v1.1.0
      source  = "github.com/hashicorp/amazon"
    }

    /*
    azure = {
      version = ">= 1.0.7" # again https://github.com/hashicorp/packer-plugin-azure/releases/tag/v1.0.7
      source  = "github.com/hashicorp/azure"
    }
*/

  }
}

local "suffix" {
  expression = formatdate("YYYY-MM-DD-hh-mm-ss", timestamp())
}

data "hcp-packer-iteration" "base-image" {
  bucket_name = "base-image"
  channel     = "production"
}


/*
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
*/


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
    #    "source.azure-arm.base",
  ]

  provisioner "file" {
    source      = "index.html"
    destination = "/home/ubuntu/index.html"
  }

  provisioner "file" {
    source      = "default"
    destination = "/home/ubuntu/default"
  }

  provisioner "shell" {
    inline = [
      "sudo apt-get -yq update",
      "sudo apt-get -yq install nginx",
      "sudo mv /home/ubuntu/index.html /var/www/html/index.html",
      "sudo mv /home/ubuntu/default /etc/nginx/sites-available/default",
    ]
  }


  #
  # SBOM
  # https://developer.hashicorp.com/packer/tutorials/hcp/track-artifact-package-metadata?product_intent=packer&utm_source=bambu#generate-the-software-bill-of-materials
  #

  # Run trivy to generate the SBOM
  provisioner "shell" {
    inline = [
      "trivy fs --format cyclonedx --output /tmp/sbom_cyclonedx_${var.image_version}.json /"
    ]
  }

  # Upload SBOM
  provisioner "hcp-sbom" {
    source      = "/tmp/sbom_cyclonedx_${var.image_version}.json"
    destination = "sbom_cyclonedx_${var.image_version}.json"
    sbom_name   = "sbom-cyclonedx-ubuntu"
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
      "ubuntu-version" = "Jammy 22.04"
      "version"        = "v0.1.0"
    }
  }
}
