module "eks_cluster" {
  source       = "git::https://github.com/MSK-Staging/PfE_Managed_Kube.git//src/module/hyc-eks?ref=feature/modularize-base"
  cluster_name = "cbioportal-prod"

  # General EKS Config
  cluster_version = "1.30"
  tags = {
    Environment = "prod"
  }

  # Network Config
  vpc_id = "vpc-0003c8f263d7ed5ab"
  az-1   = "us-east-1a"
  az-2   = "us-east-1b"
  az-3   = "us-east-1d"

  # API Controls
  cluster_endpoint_public  = false
  cluster_endpoint_private = true
  use_public_for_private   = true

  # EKS Managed Node Groups
  eks_managed_node_groups = {
    cbioportal = {
      instance_types = ["r5.xlarge"]
      ami_type       = "BOTTLEROCKET_x86_64"
      desired_size   = 1
      max_size       = 1
      min_size       = 1
    }
  }
}