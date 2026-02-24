terraform {
  required_version = "~> 1.14.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.22"
    }
  }

  # Use s3 bucket to store terraform state. Use s3 state locking https://developer.hashicorp.com/terraform/language/backend/s3#use_lockfile-1
  backend "s3" {
    bucket       = "k8s-terraform-state-storage-203403084713"
    key          = "terraform/203403084713/eks.tfstate"
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