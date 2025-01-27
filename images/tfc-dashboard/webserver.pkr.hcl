packer {
  required_plugins {
    amazon = {
      version = ">= 1.1.0" # for SSH stuff https://github.com/hashicorp/packer-plugin-amazon/releases/tag/v1.1.0
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "image_version" {
  type    = string
  default = "v0.1.0"
}

local "suffix" {
  expression = formatdate("YYYY-MM-DD-hh-mm-ss", timestamp())
}

data "hcp-packer-iteration" "base-image" {
  bucket_name = "base-image"
  channel     = "production"
}

data "hcp-packer-image" "aws-base-image" {
  bucket_name    = "base-image"
  iteration_id   = data.hcp-packer-iteration.base-image.id
  cloud_provider = "aws"
  region         = "eu-west-2"
}
source "amazon-ebs" "base" {
  ami_name = "strawbtest/demo/tfc-dashboard/${local.suffix}"

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
    Purpose = "HCP TF Dashboard"
    TTL     = "30d"
    Packer  = true
    Source  = "https://github.com/hashi-strawb/packer-golden-image/tree/main/images/tfc-dashboard/"
  }

  # Tell AWS to deprecate the image after 30 days
  deprecate_at = timeadd(timestamp(), "720h")


  ssh_username = "ubuntu"
}

build {
  name = "tfc-dashboard"

  sources = [
    "source.amazon-ebs.base",
  ]

  provisioner "shell" {
    inline = [
      "mkdir /home/ubuntu/html/"
    ]
  }

  provisioner "file" {
    source      = "html/"
    destination = "/home/ubuntu/html/"
  }

  provisioner "file" {
    source      = "default"
    destination = "/home/ubuntu/default"
  }

  provisioner "shell" {
    inline = [
      "sudo apt-get -yq update",
      "sudo apt-get -yq install nginx",
      "sudo mv /home/ubuntu/html/* /var/www/html/",
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
    bucket_name = "tfc-dashboard"

    description = <<EOT
HCP Terraform Dashboard
    EOT

    bucket_labels = {
      "owner"  = "platform-team"
      "Source" = "https://github.com/hashi-strawb/packer-golden-image/tree/main/images/tfc-dashboard/"
    }

    build_labels = {
      "os"             = "Ubuntu"
      "ubuntu-version" = "Jammy 22.04"
    }
  }
}
