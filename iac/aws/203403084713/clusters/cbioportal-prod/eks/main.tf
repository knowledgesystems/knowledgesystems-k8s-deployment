locals {
  # Use locals for node groups to enforce required tags
  node_groups = {
    cbioportal = {
      instance_types = ["r7g.xlarge"]
      ami_type       = "BOTTLEROCKET_ARM_64"
      desired_size   = 4
      max_size       = 5
      min_size       = 4
      version        = 1.32
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
      version        = 1.32
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
      instance_types = ["r7g.large"]
      ami_type       = "BOTTLEROCKET_ARM_64"
      desired_size   = 3
      max_size       = 3
      min_size       = 2
      version        = 1.32
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
      version        = 1.32
    }
    redis = {
      instance_types = ["r7g.xlarge"]
      ami_type       = "BOTTLEROCKET_ARM_64"
      desired_size   = 4
      max_size       = 5
      min_size       = 4
      version        = 1.32
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
    datadog = {
      instance_types = ["t3.medium"]
      ami_type       = "BOTTLEROCKET_x86_64"
      desired_size   = 2
      min_size       = 1
      max_size       = 3
      version        = 1.32
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
    paladin = {
      instance_types = ["t3.xlarge"]
      ami_type       = "BOTTLEROCKET_x86_64"
      desired_size   = 2
      min_size       = 2
      max_size       = 2
      version        = 1.32
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
    gn-database = {
      instance_types = ["r7i.2xlarge"]
      ami_type       = "BOTTLEROCKET_x86_64"
      desired_size   = 4
      min_size       = 4
      max_size       = 4
      subnet_ids     = ["subnet-01e2143c0b3d4f8a6"]
      block_device_mappings = {
        root_vol = var.ROOT_VOL_CONFIG
        data_vol = var.DATA_VOL_CONFIG
      }
      taints = {
        dedicated = {
          key    = var.TAINT_KEY
          value  = "gn-database"
          effect = var.TAINT_EFFECT
        }
      }
      labels = {
        (var.LABEL_KEY) = "gn-database"
      }
      tags = {
        cdsi-app   = "genome-nexus"
        cdsi-team  = "data-visualization"
        cdsi-owner = "lix2@mskcc.org"
      }
    }
    gn-vep = {
      instance_types = ["r7i.xlarge"]
      ami_type       = "BOTTLEROCKET_x86_64"
      desired_size   = 1
      min_size       = 1
      max_size       = 1
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
    cellxgene = {
      instance_types = ["r7g.large"]
      ami_type       = "BOTTLEROCKET_ARM_64"
      desired_size   = 2
      min_size       = 1
      max_size       = 3
      version        = 1.32
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
    keycloak = {
      instance_types = ["t3.medium"]
      ami_type       = "BOTTLEROCKET_x86_64"
      desired_size   = 1
      min_size       = 1
      max_size       = 1
      version        = 1.32
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
    oncokb-beta = {
      instance_types = ["r7g.large"]
      ami_type       = "BOTTLEROCKET_ARM_64"
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
          value  = "oncokb-beta"
          effect = var.TAINT_EFFECT
        }
      }
      labels = {
        (var.LABEL_KEY) = "oncokb-beta"
      }
      tags = {
        cdsi-app   = "oncokb"
        cdsi-team  = "oncokb"
        cdsi-owner = "luc2@mskcc.org"
      }
    }
    oncokb = {
      instance_types = ["r7i.2xlarge"]
      ami_type       = "BOTTLEROCKET_x86_64"
      desired_size   = 3
      min_size       = 3
      max_size       = 3
      taints = {
        dedicated = {
          key    = var.TAINT_KEY
          value  = "oncokb"
          effect = var.TAINT_EFFECT
        }
      }
      labels = {
        (var.LABEL_KEY) = "oncokb"
      }
      tags = {
        cdsi-app   = "oncokb"
        cdsi-team  = "oncokb"
        cdsi-owner = "luc2@mskcc.org"
      }
    }
    oncokb-redis = {
      instance_types = ["r7i.2xlarge"]
      ami_type       = "BOTTLEROCKET_x86_64"
      desired_size   = 1
      min_size       = 1
      max_size       = 1
      # Pin to a single subnet. This prevents nodegroup to be created in a availability zone different from the underlying persistent volumes
      subnet_ids = ["subnet-0b42183b1df0e9061"]
      taints = {
        dedicated = {
          key    = var.TAINT_KEY
          value  = "oncokb-redis"
          effect = var.TAINT_EFFECT
        }
      }
      labels = {
        (var.LABEL_KEY) = "oncokb-redis"
      }
      tags = {
        cdsi-app   = "oncokb"
        cdsi-team  = "oncokb"
        cdsi-owner = "luc2@mskcc.org"
      }
    }
    oncokb-af = {
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
          value  = "oncokb-af"
          effect = var.TAINT_EFFECT
        }
      }
      labels = {
        (var.LABEL_KEY) = "oncokb-af"
      }
      tags = {
        cdsi-app   = "oncokb"
        cdsi-team  = "oncokb"
        cdsi-owner = "luc2@mskcc.org"
      }
    }
    cbioagent = {
      instance_types = ["m7g.large"]
      ami_type       = "BOTTLEROCKET_ARM_64"
      desired_size   = 2
      max_size       = 2
      min_size       = 2
      version        = 1.32
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
    prometheus = {
      instance_types = ["t3.large"]
      ami_type       = "BOTTLEROCKET_x86_64"
      desired_size   = 1
      max_size       = 1
      min_size       = 1
      version        = 1.32
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
  }
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

resource "aws_eks_addon" "s3_mountpoint_addon" {
  addon_name                  = "aws-mountpoint-s3-csi-driver"
  addon_version               = "v1.15.0-eksbuild.1"
  cluster_name                = "cbioportal-prod-a9438edd"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  service_account_role_arn    = "arn:aws:iam::203403084713:role/userServiceRoleCellxgeneS3Mountpoint"
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