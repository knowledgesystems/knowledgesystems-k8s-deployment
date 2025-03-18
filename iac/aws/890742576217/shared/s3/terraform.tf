terraform {
  required_version = "~> 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket       = "k8s-terraform-state-storage-890742576217"
    key          = "terraform/890742576217/s3.tfstate"
    region       = "us-east-1"
    // use_lockfile = false // Not available on TF 1.6
  }
}

provider "aws" {
  region  = var.AWS_REGION
  profile = var.AWS_PROFILE
  default_tags {
    tags = var.AWS_DEFAULT_TAGS
  }
}
