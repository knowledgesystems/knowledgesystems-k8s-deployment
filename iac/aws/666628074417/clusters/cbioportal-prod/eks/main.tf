module "eks_cluster" {
  source       = "git::https://github.com/MSK-Staging/PfE_Managed_Kube.git//src/module/hyc-eks?ref=feature/modularize-base"
  cluster_name = "cbioportal-prod"

  # General EKS Config
  cluster_version = "1.30"
  tags = {
    Environment = "prod"
  }

  # Network Config
  vpc_id = "vpc-016649a093bc6177a"
  azs    = ["us-east-1a", "us-east-1b", "us-east-1c"]

  # API Controls
  cluster_endpoint_public  = true
  cluster_endpoint_private = true

  # EKS Managed Node Groups
  eks_managed_node_groups = {
    cbioportal = {
      instance_types = ["r5.large"]
      ami_type       = "BOTTLEROCKET_x86_64"
      desired_size   = 4
      max_size       = 4
      min_size       = 4
    }
  }
}