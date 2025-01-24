terraform {
  # Lock Terraform version to “~> 1.10.4” using pessimistic version constraint
  required_version = "~> 1.10.4"

  # Lock AWS Provider to major version “~> 5.0” using pessimistic version constraint
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Use s3 bucket to store terraform state.
  backend "s3" {
    bucket         = "k8s-terraform-state-storage"
    key            = "terraform/666628074417/clusters/cbioportal-prod/eks.tfstate"
    region         = "us-east-1"
  }
}

provider "aws" {
  region  = "us-east-1"
  profile = "cbioportal-msk-666628074417"
}