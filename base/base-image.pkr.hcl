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

variable "image_version" {
  type    = string
  default = "v0.1.0"
}

local "suffix" {
  expression = formatdate("YYYY-MM-DD-hh-mm-ss", timestamp())
}

/*
source "azure-arm" "ubuntu" {
  use_azure_cli_auth = true

  os_type         = "Linux"
  image_publisher = "canonical"
  image_offer     = "0001-com-ubuntu-server-jammy"
  image_sku       = "22_04-lts-gen2"

  vm_size = "Standard_B1ls"

  build_resource_group_name = "strawb-packerdemo"

  managed_image_resource_group_name = "strawb-packerdemo"
  managed_image_name                = "strawbtest-demo-base-${var.image_version}-${local.suffix}"

  ssh_username = "ubuntu"
}
*/

source "amazon-ebs" "ubuntu" {
  ami_name = "strawbtest/demo/base/${var.image_version}/${local.suffix}"

  instance_type = "t2.micro"

  source_ami_filter {
    filters = {
      name                = "ubuntu/images/*ubuntu-jammy-22.04-amd64-server-*"
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
    TTL     = "30d"
    Packer  = true
    Source  = "https://github.com/hashi-strawb/packer-golden-image/tree/main/base/"
  }

  # Tell AWS to deprecate the image after 30 days
  deprecate_at = timeadd(timestamp(), "720h")

  ssh_username = "ubuntu"
}

build {
  name = "provision"

  sources = [
    "source.amazon-ebs.ubuntu",
    #    "source.azure-arm.ubuntu",
  ]

  provisioner "shell" {
    script = "provision.sh"
  }


  #
  # SBOM
  # https://developer.hashicorp.com/packer/tutorials/hcp/track-artifact-package-metadata?product_intent=packer&utm_source=bambu#generate-the-software-bill-of-materials
  #

  # Install trivy
  provisioner "shell" {
    inline = [
      "curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sudo sh -s -- -b /usr/local/bin latest"
    ]
  }

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
    bucket_name = "base-image"

    description = <<EOT
Golden Base Image
    EOT

    bucket_labels = {
      "owner" = "platform-team"
    }

    build_labels = {
      "os"             = "Ubuntu"
      "ubuntu-version" = "Jammy 22.04"
      "version"        = "${var.image_version}"
    }
  }
}
