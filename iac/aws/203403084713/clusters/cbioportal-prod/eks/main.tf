module "eks_cluster" {
  source       = "git::https://github.com/MSK-Staging/PfE_Managed_Kube.git//src/module/hyc-eks?ref=feature/modularize-base"
  cluster_name = "cbioportal-prod"

  # General EKS Config
  cluster_version = "1.30"
  tags = {
    Environment = "prod"
  }

  # Network Config
  vpc_id = "vpc-0ee88fb9792a81d88"
  azs    = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d"]

  # API Controls
  cluster_endpoint_public  = true
  cluster_endpoint_private = true

  # EKS Managed Node Groups
  eks_managed_node_groups = {
    cbioportal = {
      instance_types = ["r7g.xlarge"]
      ami_type       = "BOTTLEROCKET_ARM_64"
      desired_size   = 1
      max_size       = 1
      min_size       = 1
    }
  }
}
