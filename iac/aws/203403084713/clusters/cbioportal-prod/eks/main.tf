data "aws_caller_identity" "current" {}

locals {
  # Use locals for node groups to enforce required tags
  node_groups = {
    cbioportal = {
      instance_types = ["r7g.xlarge"]
      ami_type       = "BOTTLEROCKET_ARM_64"
      desired_size   = 2
      max_size       = 3
      min_size       = 2
      subnet_ids     = ["subnet-0d2671d84a3f5eb99", "subnet-06f2712e78e593152", "subnet-001ff98812a2e49e5", "subnet-0b42183b1df0e9061", "subnet-01b9abeeefc878fc4", "subnet-03225fc0c62f573b7"]
      taints = {
        dedicated = {
          key    = var.TAINT_KEY
          value  = "cbioportal"
          effect = var.TAINT_EFFECT
        }
      }
      labels = {
        (var.LABEL_KEY) = "cbioportal"
      }
    }
    cbio-genie = {
      instance_types = ["r7g.large"]
      ami_type       = "BOTTLEROCKET_ARM_64"
      desired_size   = 3
      max_size       = 4
      min_size       = 3
      subnet_ids     = ["subnet-0d2671d84a3f5eb99", "subnet-06f2712e78e593152", "subnet-001ff98812a2e49e5", "subnet-0b42183b1df0e9061", "subnet-01b9abeeefc878fc4", "subnet-03225fc0c62f573b7"]
      taints = {
        dedicated = {
          key    = var.TAINT_KEY
          value  = "cbio-genie"
          effect = var.TAINT_EFFECT
        }
      }
      labels = {
        (var.LABEL_KEY) = "cbio-genie"
      }
    }
    cbio-dev = {
      instance_types = ["r8g.large"]
      ami_type       = "BOTTLEROCKET_ARM_64"
      desired_size   = 2
      max_size       = 2
      min_size       = 2
      subnet_ids     = ["subnet-0d2671d84a3f5eb99", "subnet-06f2712e78e593152", "subnet-001ff98812a2e49e5", "subnet-0b42183b1df0e9061", "subnet-01b9abeeefc878fc4", "subnet-03225fc0c62f573b7"]
      block_device_mappings = {
        root_vol = var.ROOT_VOL_CONFIG
        data_vol = var.DATA_VOL_CONFIG
      }
      taints = {
        dedicated = {
          key    = var.TAINT_KEY
          value  = "cbio-dev"
          effect = var.TAINT_EFFECT
        }
      }
      labels = {
        (var.LABEL_KEY) = "cbio-dev"
      }
    }
    argocd = {
      instance_types = ["m5.large"]
      ami_type       = "BOTTLEROCKET_x86_64"
      desired_size   = 2
      max_size       = 3
      min_size       = 2
      labels = {
        "karpenter.sh/controller" = "true"
      }
    }
    redis = {
      instance_types = ["r7g.large"]
      ami_type       = "BOTTLEROCKET_ARM_64"
      desired_size   = 2
      max_size       = 2
      min_size       = 2
      block_device_mappings = {
        root_vol = var.ROOT_VOL_CONFIG
        data_vol = var.DATA_VOL_CONFIG
      }
      taints = {
        dedicated = {
          key    = var.TAINT_KEY
          value  = "cbioportal-redis"
          effect = var.TAINT_EFFECT
        }
      }
      labels = {
        (var.LABEL_KEY) = "redis"
      }
    }
    ingress = {
      instance_types = ["t3.medium"]
      ami_type       = "BOTTLEROCKET_x86_64"
      desired_size   = 2
      min_size       = 2
      max_size       = 3
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
    paladin = {
      instance_types = ["t3.xlarge"]
      ami_type       = "BOTTLEROCKET_x86_64"
      desired_size   = 2
      min_size       = 2
      max_size       = 2
      subnet_ids     = ["subnet-0d2671d84a3f5eb99", "subnet-06f2712e78e593152", "subnet-001ff98812a2e49e5", "subnet-0b42183b1df0e9061", "subnet-01b9abeeefc878fc4", "subnet-03225fc0c62f573b7"]
      taints = {
        dedicated = {
          key    = var.TAINT_KEY
          value  = "paladin"
          effect = var.TAINT_EFFECT
        }
      }
      labels = {
        (var.LABEL_KEY) = "paladin"
      }
      tags = {
        cdsi-app   = "paladin"
        cdsi-team  = "data-engineering"
        cdsi-owner = "moored2@mskcc.org"
      }
    }
    cbio-session = {
      instance_types = ["r7i.xlarge"]
      ami_type       = "BOTTLEROCKET_x86_64"
      desired_size   = 1
      min_size       = 1
      max_size       = 2
      # Pin to a single subnet. This prevents nodegroup to be created in a availability zone different from the underlying mongodb volume during rolling upgrades
      subnet_ids = ["subnet-066aca23688737c91"]
      taints = {
        dedicated = {
          key    = var.TAINT_KEY
          value  = "cbio-session"
          effect = var.TAINT_EFFECT
        }
      }
      labels = {
        (var.LABEL_KEY) = "cbio-session"
      }
      tags = {
        cdsi-app   = "cbioportal"
        cdsi-team  = "data-visualization"
        cdsi-owner = "nasirz1@mskcc.org"
      }
    }
    gn-db-sm = {
      instance_types = ["r7g.large"]
      ami_type       = "BOTTLEROCKET_ARM_64"
      desired_size   = 1
      min_size       = 1
      max_size       = 1
      subnet_ids     = ["subnet-01e2143c0b3d4f8a6", "subnet-066aca23688737c91"]
      block_device_mappings = {
        root_vol = var.ROOT_VOL_CONFIG
        data_vol = var.DATA_VOL_CONFIG
      }
      taints = {
        dedicated = {
          key    = var.TAINT_KEY
          value  = "gn-db-sm"
          effect = var.TAINT_EFFECT
        }
      }
      labels = {
        (var.LABEL_KEY) = "gn-db-sm"
      }
      tags = {
        cdsi-app   = "genome-nexus"
        cdsi-team  = "data-visualization"
        cdsi-owner = "lix2@mskcc.org"
      }
    }
    gn-db-md = {
      instance_types = ["r7g.xlarge"]
      ami_type       = "BOTTLEROCKET_ARM_64"
      desired_size   = 2
      min_size       = 2
      max_size       = 2
      subnet_ids     = ["subnet-01e2143c0b3d4f8a6", "subnet-066aca23688737c91"]
      block_device_mappings = {
        root_vol = var.ROOT_VOL_CONFIG
        data_vol = var.DATA_VOL_CONFIG
      }
      taints = {
        dedicated = {
          key    = var.TAINT_KEY
          value  = "gn-db-md"
          effect = var.TAINT_EFFECT
        }
      }
      labels = {
        (var.LABEL_KEY) = "gn-db-md"
      }
      tags = {
        cdsi-app   = "genome-nexus"
        cdsi-team  = "data-visualization"
        cdsi-owner = "lix2@mskcc.org"
      }
    }
    gn-db-lg = {
      instance_types = ["r7g.2xlarge"]
      ami_type       = "BOTTLEROCKET_ARM_64"
      desired_size   = 2
      min_size       = 2
      max_size       = 2
      subnet_ids     = ["subnet-01e2143c0b3d4f8a6", "subnet-066aca23688737c91"]
      block_device_mappings = {
        root_vol = var.ROOT_VOL_CONFIG
        data_vol = var.DATA_VOL_CONFIG
      }
      taints = {
        dedicated = {
          key    = var.TAINT_KEY
          value  = "gn-db-lg"
          effect = var.TAINT_EFFECT
        }
      }
      labels = {
        (var.LABEL_KEY) = "gn-db-lg"
      }
      tags = {
        cdsi-app   = "genome-nexus"
        cdsi-team  = "data-visualization"
        cdsi-owner = "lix2@mskcc.org"
      }
    }
    gn-vep = {
      instance_types = ["t3.large"]
      ami_type       = "BOTTLEROCKET_x86_64"
      desired_size   = 2
      min_size       = 2
      max_size       = 2
      block_device_mappings = {
        root_vol = var.ROOT_VOL_CONFIG
        data_vol = var.DATA_VOL_CONFIG
      }
      taints = {
        dedicated = {
          key    = var.TAINT_KEY
          value  = "gn-vep"
          effect = var.TAINT_EFFECT
        }
      }
      labels = {
        (var.LABEL_KEY) = "gn-vep"
      }
      tags = {
        cdsi-app   = "gn-vep"
        cdsi-team  = "data-visualization"
        cdsi-owner = "lix2@mskcc.org"
      }
    }
    genome-nexus = {
      instance_types = ["r7i.xlarge"]
      ami_type       = "BOTTLEROCKET_x86_64"
      desired_size   = 3
      min_size       = 2
      max_size       = 3
      block_device_mappings = {
        root_vol = var.ROOT_VOL_CONFIG
        data_vol = var.DATA_VOL_CONFIG
      }
      taints = {
        dedicated = {
          key    = var.TAINT_KEY
          value  = "genome-nexus"
          effect = var.TAINT_EFFECT
        }
      }
      labels = {
        (var.LABEL_KEY) = "genome-nexus"
      }
      tags = {
        cdsi-app   = "genome-nexus"
        cdsi-team  = "data-visualization"
        cdsi-owner = "lix2@mskcc.org"
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
      tags = {
        cdsi-app   = "cbioagent"
        cdsi-team  = "data-visualization"
        cdsi-owner = "nasirz1@mskcc.org"
      }
    }
    cbioagent-db = {
      instance_types = ["t3.small"]
      ami_type       = "BOTTLEROCKET_x86_64"
      desired_size   = 1
      max_size       = 1
      min_size       = 1
      # Pin to a single subnet. This prevents nodegroup to be created in a availability zone different from the underlying persistent volumes
      subnet_ids = ["subnet-001ff98812a2e49e5"]
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
      tags = {
        cdsi-app   = "cbioagent"
        cdsi-team  = "data-visualization"
        cdsi-owner = "nasirz1@mskcc.org"
      }
    }
    k8s-cost = {
      instance_types = ["t3.small"]
      ami_type       = "BOTTLEROCKET_x86_64"
      desired_size   = 1
      max_size       = 1
      min_size       = 1
      taints = {
        dedicated = {
          key    = var.TAINT_KEY
          value  = "k8s-cost"
          effect = var.TAINT_EFFECT
        }
      }
      labels = {
        (var.LABEL_KEY) = "k8s-cost"
      }
      tags = {
        cdsi-app   = "k8s-cost-dashboard"
        cdsi-team  = "data-visualization"
        cdsi-owner = "nasirz1@mskcc.org"
      }
    }
    cbio-api = {
      instance_types = ["t4g.large"]
      ami_type       = "BOTTLEROCKET_ARM_64"
      desired_size   = 2
      max_size       = 2
      min_size       = 2
      subnet_ids     = ["subnet-0d2671d84a3f5eb99", "subnet-06f2712e78e593152", "subnet-001ff98812a2e49e5", "subnet-0b42183b1df0e9061", "subnet-01b9abeeefc878fc4", "subnet-03225fc0c62f573b7"]
      taints = {
        dedicated = {
          key    = var.TAINT_KEY
          value  = "cbio-api"
          effect = var.TAINT_EFFECT
        }
      }
      labels = {
        (var.LABEL_KEY) = "cbio-api"
      }
    }
  }

  karpenter_discovery_tag_value = var.CLUSTER_NAME
  account_id                    = data.aws_caller_identity.current.account_id
  permissions_boundary_policy   = "AutomationOrUserServiceRolePermissions"
}

module "eks_cluster" {
  source       = "git::https://github.com/MSK-Staging/cbioportal-terraform.git//src/module/hyc-eks?ref=feature/modularize-base"
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
  cluster_endpoint_public  = var.API_PUBLIC
  cluster_endpoint_private = var.API_PRIVATE

  # Addon config
  hyc_addon_configs = var.ADDON_CONFIG

  # Disable cloudwatch logging
  cluster_enabled_log_types   = []
  create_cloudwatch_log_group = false

  node_security_group_tags = {
    "karpenter.sh/discovery" = local.karpenter_discovery_tag_value
  }

  # EKS Managed Node Groups
  eks_managed_node_groups = {
    for name, config in local.node_groups : name => merge(config, {
      cluster_version = try(config.version, var.NODEGROUP_VER)
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

module "iam" {
  source                    = "../iam"
  cluster_oidc_provider_arn = module.eks_cluster.cluster_oidc_provider
  cluster_name              = basename(module.eks_cluster.cluster_arn)
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

module "ec2" {
  source = "../ec2"
}

/*
Karpenter
 */

module "karpenter" {
  source       = "git::https://github.com/terraform-aws-modules/terraform-aws-eks.git//modules/karpenter?ref=v21.9.0"
  cluster_name = module.eks_cluster.cluster_name

  iam_role_name                     = "userServiceRole-KarpenterController"
  iam_role_use_name_prefix          = false
  iam_role_permissions_boundary_arn = "arn:aws:iam::${local.account_id}:policy/${local.permissions_boundary_policy}"

  node_iam_role_name                 = "userServiceRole-KarpenterNode"
  node_iam_role_use_name_prefix      = false
  node_iam_role_permissions_boundary = "arn:aws:iam::${local.account_id}:policy/${local.permissions_boundary_policy}"

  iam_policy_name            = "userServicePolicy-KarpenterController"
  iam_policy_use_name_prefix = false

  create_instance_profile = true
}

resource "helm_release" "karpenter" {
  namespace  = "kube-system"
  name       = "karpenter"
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"
  version    = "1.11.1"

  values = [
    yamlencode({
      settings = {
        clusterName       = module.eks_cluster.cluster_name
        clusterEndpoint   = module.eks_cluster.cluster_endpoint
        interruptionQueue = module.karpenter.queue_name
      }
      nodeSelector = {
        "karpenter.sh/controller" = "true"
      }
    })
  ]
}