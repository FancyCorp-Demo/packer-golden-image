terraform {
  cloud {
    organization = "fancycorp"

    workspaces {
      name = "packer-aws-auth"
    }
  }

  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  default_tags {
    tags = {
      Name      = "StrawbTest - ${terraform.workspace}"
      Owner     = "lucy.davinhart@hashicorp.com"
      Purpose   = "Packer Builds"
      TTL       = "persistent"
      Terraform = "true"
      Source    = "https://github.com/FancyCorp-Demo/packer-golden-image/tree/main/terraform/aws"
      Workspace = terraform.workspace
    }
  }
  region = var.aws-region
}
