terraform {
  required_version = ">= 1.11"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.22"
    }
  }

  backend "s3" {
    bucket       = "k8s-terraform-state-storage-397229547211"
    key          = "terraform/397229547211/cbio-claw.tfstate"
    region       = "us-east-1"
    use_lockfile = true
  }
}

provider "aws" {
  region              = "us-east-1"
  profile             = var.AWS_PROFILE
  allowed_account_ids = ["397229547211"]
}
