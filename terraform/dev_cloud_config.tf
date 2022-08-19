terraform {

  cloud {
    organization = "post-office"
    workspaces {
      name = "post-office-severless-dev"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}