terraform {
  required_version = ">= 1.10.4"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket       = "k8s-terraform-state-storage-203403084713"
    key          = "terraform/203403084713/rds.tfstate"
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

data "terraform_remote_state" "secretsmanager" {
  backend = "s3"
  config = {
    bucket = "k8s-terraform-state-storage-203403084713"
    key    = "terraform/203403084713/secretsmanager.tfstate"
    region = "us-east-1"
  }
}
