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
    curation = {
      instance_types = ["t4g.large"]
      ami_type       = "BOTTLEROCKET_ARM_64"
      desired_size   = 3
      max_size       = 3
      min_size       = 3
      taints = {
        dedicated = {
          key    = var.TAINT_KEY
          value  = "curation"
          effect = var.TAINT_EFFECT
        }
      }
      labels = {
        (var.LABEL_KEY) = "curation"
      }
      tags = {
        cdsi-app   = "curation"
        cdsi-team  = "oncokb"
        cdsi-owner = "luc2@mskcc.org"
      }
    }
    main = {
      instance_types = ["r7g.2xlarge"]
      ami_type       = "BOTTLEROCKET_ARM_64"
      desired_size   = 2
      max_size       = 2
      min_size       = 2
      taints = {
        dedicated = {
          key    = var.TAINT_KEY
          value  = "main"
          effect = var.TAINT_EFFECT
        }
      }
      labels = {
        (var.LABEL_KEY) = "main"
      }
      tags = {
        cdsi-app   = "main"
        cdsi-team  = "oncokb"
        cdsi-owner = "luc2@mskcc.org"
      }
    }
    airflow = {
      instance_types = ["t4g.large"]
      ami_type       = "BOTTLEROCKET_ARM_64"
      desired_size   = 2
      min_size       = 2
      max_size       = 2
      block_device_mappings = {
        root_vol = var.ROOT_VOL_CONFIG
      }
      taints = {
        dedicated = {
          key    = var.TAINT_KEY
          value  = "airflow"
          effect = var.TAINT_EFFECT
        }
      }
      labels = {
        (var.LABEL_KEY) = "airflow"
      }
      tags = {
        cdsi-app   = "airflow"
        cdsi-team  = "oncokb"
        cdsi-owner = "luc2@mskcc.org"
      }
    }
    redis-cl = {
      instance_types = ["r7g.xlarge"]
      ami_type       = "BOTTLEROCKET_ARM_64"
      desired_size   = 2
      max_size       = 2
      min_size       = 2
      taints = {
        dedicated = {
          key    = var.TAINT_KEY
          value  = "redis-cl"
          effect = var.TAINT_EFFECT
        }
      }
      labels = {
        (var.LABEL_KEY) = "redis-cl"
      }
      tags = {
        cdsi-app   = "redis-cl"
        cdsi-team  = "oncokb"
        cdsi-owner = "luc2@mskcc.org"
      }
    }
    beta = {
      instance_types = ["t4g.large"]
      ami_type       = "BOTTLEROCKET_ARM_64"
      desired_size   = 1
      max_size       = 1
      min_size       = 1
      taints = {
        dedicated = {
          key    = var.TAINT_KEY
          value  = "beta"
          effect = var.TAINT_EFFECT
        }
      }
      labels = {
        (var.LABEL_KEY) = "beta"
      }
      tags = {
        cdsi-app   = "beta"
        cdsi-team  = "oncokb"
        cdsi-owner = "luc2@mskcc.org"
      }
    }
    nonessential = {
      instance_types = ["t4g.medium"]
      ami_type       = "BOTTLEROCKET_ARM_64"
      desired_size   = 2
      max_size       = 2
      min_size       = 2
      taints = {
        dedicated = {
          key    = var.TAINT_KEY
          value  = "nonessential"
          effect = var.TAINT_EFFECT
        }
      }
      labels = {
        (var.LABEL_KEY) = "nonessential"
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
