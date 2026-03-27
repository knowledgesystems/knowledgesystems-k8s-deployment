locals {
  # Use locals for node groups to enforce required tags
  node_groups = {
    addons = {
      instance_types = ["t3.large"]
      ami_type       = "BOTTLEROCKET_x86_64"
      desired_size   = 1
      max_size       = 1
      min_size       = 1
    }
    ingress = {
      instance_types = ["t3.medium"]
      ami_type       = "BOTTLEROCKET_x86_64"
      desired_size   = 2
      min_size       = 2
      max_size       = 2
      taints = {
        dedicated = {
          key    = var.TAINT_KEY
          value  = "ingress"
          effect = var.TAINT_EFFECT
        }
      }
      labels = {
        (var.LABEL_KEY) = "ingress"
      }
    }
  }
}

module "eks_cluster" {
  source       = "git::https://github.com/MSK-Staging/terraform-aws-hyc-eks.git?ref=4.0.0"
  cluster_name = var.CLUSTER_NAME

  # General EKS Config
  cluster_version = var.CLUSTER_VER
  tags = {
    Environment = var.CLUSTER_ENV
  }

  # Network Config
  vpc_id                   = var.VPC_ID
  control_plane_subnet_ids = var.CONTROL_PLANE_SUBNET_IDS
  subnet_ids               = var.SUBNET_IDS

  # Disable logging to avoid Cloudwatch costs
  cluster_enabled_log_types   = []
  create_cloudwatch_log_group = false

  # API Controls
  cluster_endpoint_public_access  = var.API_PUBLIC
  cluster_endpoint_private_access = var.API_PRIVATE

  # Addon config
  hyc_addon_configs = var.ADDON_CONFIG

  # EKS Managed Node Groups
  eks_managed_node_groups = {
    for name, config in local.node_groups : name => merge(config, {
      tags = merge(
        try(config.tags, var.AWS_DEFAULT_TAGS),
        {
          "nodegroup-name" = name
          "resource-name"  = name
        }
      )
    })
  }
}