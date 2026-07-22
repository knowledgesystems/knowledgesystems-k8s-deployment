data "aws_caller_identity" "current" {}

locals {
  # Confirm this policy exists in account 666628074417 before applying.
  permissions_boundary_policy = "AutomationOrUserServiceRolePermissions"
  account_id                        = data.aws_caller_identity.current.account_id
  karpenter_controller_role_name    = "userServiceRole-KarpenterController"
  karpenter_node_role_name          = "userServiceRole-KarpenterNode"
  karpenter_discovery_tag_value     = var.CLUSTER_NAME

  # Use locals for node groups to enforce required tags
  node_groups = {
    addons = {
      instance_types = ["m5.large"]
      ami_type       = "BOTTLEROCKET_x86_64"
      desired_size   = 2
      max_size       = 3
      min_size       = 2
      # Hosts the Karpenter controller, which must not run on the nodes it manages.
      labels = {
        "karpenter.sh/controller" = "true"
      }
    }
    ingress = {
      instance_types = ["m5.large"]
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
    redis = {
      instance_types = ["t3.medium"]
      ami_type       = "BOTTLEROCKET_x86_64"
      desired_size   = 2
      min_size       = 2
      max_size       = 2
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
      instance_types = ["m5.large"]
      ami_type       = "BOTTLEROCKET_x86_64"
      desired_size   = 1
      min_size       = 1
      max_size       = 1
      subnet_ids     = ["subnet-0917a96517f3dad1d"]
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
    cbioagent = {
      instance_types = ["m7g.large"]
      ami_type       = "BOTTLEROCKET_ARM_64"
      desired_size   = 1
      max_size       = 1
      min_size       = 1
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
      instance_types = ["t3.medium"]
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
    oncotree = {
      instance_types = ["t3.small"]
      ami_type       = "BOTTLEROCKET_x86_64"
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
      tags = {
        cdsi-app   = "oncotree"
        cdsi-team  = "oncokb"
        cdsi-owner = "luc2@mskcc.org"
      }
    }
    cbioportal = {
      instance_types = ["r7g.large"]
      ami_type       = "BOTTLEROCKET_ARM_64"
      desired_size   = 3
      max_size       = 3
      min_size       = 3
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
    cdd = {
      instance_types = ["t3.small"]
      ami_type       = "BOTTLEROCKET_x86_64"
      desired_size   = 1
      max_size       = 1
      min_size       = 1
      taints = {
        dedicated = {
          key    = var.TAINT_KEY
          value  = "cdd"
          effect = var.TAINT_EFFECT
        }
      }
      labels = {
        (var.LABEL_KEY) = "cdd"
      }
    }
    biomni = {
      instance_types = ["m6i.large"]
      ami_type       = "BOTTLEROCKET_x86_64"
      desired_size   = 1
      max_size       = 1
      min_size       = 1
      block_device_mappings = {
        root_vol = var.ROOT_VOL_CONFIG
        data_vol = var.DATA_VOL_CONFIG
      }
      taints = {
        dedicated = {
          key    = var.TAINT_KEY
          value  = "biomni"
          effect = var.TAINT_EFFECT
        }
      }
      labels = {
        (var.LABEL_KEY) = "biomni"
      }
    }
    cbio-dev = {
      instance_types = ["t4g.large"]
      ami_type       = "BOTTLEROCKET_ARM_64"
      desired_size   = 1
      max_size       = 1
      min_size       = 1
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
    cbio-sclc = {
      instance_types = ["t4g.large"]
      ami_type       = "BOTTLEROCKET_ARM_64"
      desired_size   = 1
      max_size       = 1
      min_size       = 1
      block_device_mappings = {
        root_vol = var.ROOT_VOL_CONFIG
        data_vol = var.DATA_VOL_CONFIG
      }
      taints = {
        dedicated = {
          key    = var.TAINT_KEY
          value  = "cbio-sclc"
          effect = var.TAINT_EFFECT
        }
      }
      labels = {
        (var.LABEL_KEY) = "cbio-sclc"
      }
    }
    cbio-triage = {
      instance_types = ["t4g.large"]
      ami_type       = "BOTTLEROCKET_ARM_64"
      desired_size   = 1
      max_size       = 1
      min_size       = 1
      block_device_mappings = {
        root_vol = var.ROOT_VOL_CONFIG
        data_vol = var.DATA_VOL_CONFIG
      }
      taints = {
        dedicated = {
          key    = var.TAINT_KEY
          value  = "cbio-triage"
          effect = var.TAINT_EFFECT
        }
      }
      labels = {
        (var.LABEL_KEY) = "cbio-triage"
      }
    }
  }
}

module "eks_cluster" {
  source  = "app.terraform.io/mskcc/hyc-eks/aws"
  version = "4.0.0"
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

  # HYC addons
  hyc_addon_configs = {
    observability = {
      create = false
    }
  }

  # Tags the node security group so the Karpenter EC2NodeClass can discover it.
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
  cluster_oidc_provider_arn = module.eks_cluster.oidc_provider
  cluster_name              = basename(module.eks_cluster.cluster_arn)
}

resource "aws_eks_addon" "s3_mountpoint_addon" {
  addon_name                  = "aws-mountpoint-s3-csi-driver"
  addon_version               = "v2.7.0-eksbuild.1"
  cluster_name                = basename(module.eks_cluster.cluster_arn)
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  service_account_role_arn    = module.iam.databricks_s3_mountpoint_role_arn
  configuration_values = jsonencode({
    node = {
      tolerations = [
        {
          key      = "workload"
          operator = "Equal"
          value    = "cellxgene"
          effect   = "NoSchedule"
        },
        {
          key      = "workload"
          operator = "Equal"
          value    = "airflow-importer-dag"
          effect   = "NoSchedule"
        }
      ]
    }
  })
}

/*
Karpenter
 */

module "karpenter" {
  source       = "git::https://github.com/terraform-aws-modules/terraform-aws-eks.git//modules/karpenter?ref=v21.9.0"
  cluster_name = module.eks_cluster.cluster_name

  iam_role_name                     = local.karpenter_controller_role_name
  iam_role_use_name_prefix          = false
  iam_role_permissions_boundary_arn = "arn:aws:iam::${local.account_id}:policy/${local.permissions_boundary_policy}"

  node_iam_role_name                 = local.karpenter_node_role_name
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

# Attach the Databricks S3 mountpoint policy to the Karpenter node role
# so the s3 CSI driver can access the Databricks S3 bucket.
resource "aws_iam_role_policy_attachment" "karpenter_node_s3_mountpoint" {
  policy_arn = "arn:aws:iam::${local.account_id}:policy/userServicePolicyDatabricksS3Mountpoint"
  role       = local.karpenter_node_role_name
}
