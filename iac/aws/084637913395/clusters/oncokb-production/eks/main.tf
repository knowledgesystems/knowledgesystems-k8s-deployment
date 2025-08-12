locals {
  # Use locals for node groups to enforce required tags
  node_groups = {
    lg-general = {
      instance_types = ["t4g.xlarge"]
      ami_type       = "BOTTLEROCKET_ARM_64"
      desired_size   = 3
      max_size       = 3
      min_size       = 3
      labels = {
        (var.LABEL_KEY) = "lg-general"
      }
    }
    legacy-apps = {
      instance_types = ["t3.medium"]
      ami_type       = "BOTTLEROCKET_x86_64"
      desired_size   = 1
      max_size       = 2
      min_size       = 1
      taints = {
        dedicated = {
          key    = "workload"
          value  = "legacy-apps"
          effect = "NO_SCHEDULE"
        }
      }
      labels = {
        (var.LABEL_KEY) = "legacy-apps"
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

  hyc_addon_configs = {
    efscsi = {
      create = false
    }
    observability = {
      create = false
    }
  }

  # EKS Managed Node Groups
  eks_managed_node_groups = {
    for name, config in local.node_groups : name => merge(config, {
      tags = merge(
        try(config.tags, {}),
        {
          "nodegroup-name" = name
        }
      )
    })
  }
}