locals {
  # Use locals for node groups to enforce required tags
  node_groups = {
    addons = {
      instance_types = ["m5.large"]
      ami_type       = "BOTTLEROCKET_x86_64"
      desired_size   = 2
      max_size       = 3
      min_size       = 2
    }
    ingress = {
      instance_types = ["m5.large"]
      ami_type       = "BOTTLEROCKET_x86_64"
      desired_size   = 1
      min_size       = 1
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
    datadog = {
      instance_types = ["t3.medium"]
      ami_type       = "BOTTLEROCKET_x86_64"
      desired_size   = 2
      min_size       = 1
      max_size       = 3
      taints = {
        dedicated = {
          key    = var.TAINT_KEY
          value  = "datadog"
          effect = var.TAINT_EFFECT
        }
      }
      labels = {
        (var.LABEL_KEY) = "datadog"
      }
    }
    redis = {
      instance_types = ["t3.medium"]
      ami_type       = "BOTTLEROCKET_x86_64"
      desired_size   = 5
      min_size       = 5
      max_size       = 5
      taints = {
        dedicated = {
          key    = var.TAINT_KEY
          value  = "redis"
          effect = var.TAINT_EFFECT
        }
      }
      labels = {
        (var.LABEL_KEY) = "redis"
      }
    }
    keycloak = {
      instance_types = ["t3.medium"]
      ami_type       = "BOTTLEROCKET_x86_64"
      desired_size   = 1
      min_size       = 1
      max_size       = 1
      taints = {
        dedicated = {
          key    = var.TAINT_KEY
          value  = "keycloak"
          effect = var.TAINT_EFFECT
        }
      }
      labels = {
        (var.LABEL_KEY) = "keycloak"
      }
    }
    airflow = {
      instance_types = ["r5.xlarge"]
      ami_type       = "BOTTLEROCKET_x86_64"
      desired_size   = 1
      min_size       = 1
      max_size       = 1
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
    }
    cellxgene = {
      instance_types = ["m7g.xlarge"]
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
          value  = "cellxgene"
          effect = var.TAINT_EFFECT
        }
      }
      labels = {
        (var.LABEL_KEY) = "cellxgene"
      }
      tags = {
        cdsi-app   = "cellxgene"
        cdsi-team  = "data-visualization"
        cdsi-owner = "hweej@mskcc.org"
      }
    }
    cbioagent = {
      instance_types = ["m7g.large"]
      ami_type       = "BOTTLEROCKET_ARM_64"
      desired_size   = 2
      max_size       = 2
      min_size       = 2
      taints = {
        dedicated = {
          key    = var.TAINT_KEY
          value  = "cbioagent"
          effect = var.TAINT_EFFECT
        }
      }
      labels = {
        (var.LABEL_KEY) = "cbioagent"
      }
    }
    cbioagent-db = {
      instance_types = ["r7i.large"]
      ami_type       = "BOTTLEROCKET_x86_64"
      desired_size   = 1
      max_size       = 1
      min_size       = 1
      # Pin to a single subnet. This prevents nodegroup to be created in a availability zone different from the underlying persistent volumes
      subnet_ids = ["subnet-0917a96517f3dad1d"]
      taints = {
        dedicated = {
          key    = var.TAINT_KEY
          value  = "cbioagent-db"
          effect = var.TAINT_EFFECT
        }
      }
      labels = {
        (var.LABEL_KEY) = "cbioagent-db"
      }
    }
    prometheus = {
      instance_types = ["t3.large"]
      ami_type       = "BOTTLEROCKET_x86_64"
      desired_size   = 1
      max_size       = 1
      min_size       = 1
      taints = {
        dedicated = {
          key    = var.TAINT_KEY
          value  = "prometheus"
          effect = var.TAINT_EFFECT
        }
      }
      labels = {
        (var.LABEL_KEY) = "prometheus"
      }
    }
    oncotree = {
      instance_types = ["t4g.medium"]
      ami_type       = "BOTTLEROCKET_ARM_64"
      desired_size   = 1
      max_size       = 1
      min_size       = 1
      taints = {
        dedicated = {
          key    = var.TAINT_KEY
          value  = "oncotree"
          effect = var.TAINT_EFFECT
        }
      }
      labels = {
        (var.LABEL_KEY) = "oncotree"
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

  # Disable logging to avoid Cloudwatch costs
  cluster_enabled_log_types = []
  create_cloudwatch_log_group = false

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

module "iam" {
  source                    = "../iam"
  cluster_oidc_provider_arn = module.eks_cluster.oidc_provider
  cluster_name = basename(module.eks_cluster.cluster_arn)
}

resource "aws_eks_addon" "s3_mountpoint_addon" {
  addon_name                  = "aws-mountpoint-s3-csi-driver"
  addon_version               = "v1.15.0-eksbuild.1"
  cluster_name                = basename(module.eks_cluster.cluster_arn)
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  service_account_role_arn    = module.iam.cellxgene_s3_mountpoint_role_arn
  configuration_values = jsonencode({
    node = {
      tolerations = [
        {
          key      = "workload"
          operator = "Equal"
          value    = "cellxgene"
          effect   = "NoSchedule"
        }
      ]
    }
  })
}