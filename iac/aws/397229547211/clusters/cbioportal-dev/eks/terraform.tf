terraform {
  # Lock Terraform version to “~> 1.10.4” using pessimistic version constraint
  required_version = ">= 1.11"

  # Lock AWS Provider to major version “~> 5.0” using pessimistic version constraint
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.22"
    }
  }

  # Use s3 bucket to store terraform state. Use s3 state locking https://developer.hashicorp.com/terraform/language/backend/s3#use_lockfile-1
  backend "s3" {
    bucket       = "k8s-terraform-state-storage-397229547211"
    key          = "terraform/397229547211/eks.tfstate"
    region       = "us-east-1"
    use_lockfile = false
  }
}

provider "aws" {
  region  = var.AWS_REGION
  profile = var.AWS_PROFILE
  default_tags {
    tags = var.AWS_DEFAULT_TAGS
  }
}