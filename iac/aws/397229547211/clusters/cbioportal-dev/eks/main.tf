locals {
  # Use locals for node groups to enforce required tags
  node_groups = {
    addons = {
      instance_types = ["m5.large"]
      ami_type       = "BOTTLEROCKET_x86_64"
      desired_size   = 2
      max_size       = 3
      min_size       = 2
      block_device_mappings = {
        root_vol = var.ROOT_VOL_CONFIG
      }
    }
  }
}

module "eks_cluster" {
  source       = "git::https://github.com/MSK-Staging/terraform-aws-hyc-eks.git"
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

  # API Controls
  cluster_endpoint_public_access  = var.API_PUBLIC
  cluster_endpoint_private_access = var.API_PRIVATE

  # HYC addons
  hyc_addon_configs = {
    observability = {
      create = false
    }
  }

  # EKS Managed Node Groups
  eks_managed_node_groups = {
    for name, config in local.node_groups : name => merge(config, {
      cluster_version = try(config.version, var.NODEGROUP_VER)
      tags = merge(
        try(config.tags, {}),
        {
          "nodegroup-name" = name
        }
      )
    })
  }
}