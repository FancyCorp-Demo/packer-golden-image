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


module "oidc_github" {
  source  = "unfunco/oidc-github/aws"
  version = "1.8.0"

  github_repositories = [
    "FancyCorp-Demo/packer-golden-image",

    # TODO: be more specific; only allow the "main" branch initially
    # see https://registry.terraform.io/modules/unfunco/oidc-github/aws/latest for example
    # "another-org/another-repo:ref:refs/heads/main",
    #
    # Future versions, we could figure out how to do this for PRs... for approved users (i.e. me)

  ]
}
