variable "AWS_PROFILE" {
  description = "AWS cli profile"
  type        = string
  ephemeral   = true
  default     = "default"
}

variable "AWS_REGION" {
  description = "AWS cli region"
  type        = string
  default     = "us-east-1"
}

variable "AWS_DEFAULT_TAGS" {
  description = "Set of default tags that get added to all resources. Avoid changing this as this updates a lot of resources and could lead to disruption. As an alternative, change tags for the individual resources."
  type        = map(string)
  default = {
    cdsi-owner = "nasirz1@mskcc.org"
    cdsi-app   = "cbioportal"
    cdsi-team  = "data-visualization"
  }
}

variable "CLUSTER_NAME" {
  description = "Name of the cluster"
  type        = string
  default     = "cbioportal-prod"
}

variable "CLUSTER_VER" {
  description = "Kubernetes version of the cluster"
  type        = string
  default     = "1.32"
}

variable "NODEGROUP_VER" {
  description = "Kubernetes version of the nodegroups"
  type        = string
  default     = "1.32"
}

variable "CLUSTER_ENV" {
  description = "Environment value for the cluster [prod | dev]"
  type        = string
  default     = "prod"
}

variable "VPC_ID" {
  description = "VPC id for the cluster"
  type        = string
  default     = "vpc-0ee88fb9792a81d88"
}

variable "CONTROL_PLANE_SUBNET_IDS" {
  description = "A list of subnet IDs where the EKS cluster control plane (ENIs) will be provisioned"
  type        = list(string)
  default     = ["subnet-0d2671d84a3f5eb99", "subnet-06f2712e78e593152", "subnet-001ff98812a2e49e5", "subnet-066aca23688737c91", "subnet-0b42183b1df0e9061", "subnet-01b9abeeefc878fc4", "subnet-03225fc0c62f573b7", "subnet-01e2143c0b3d4f8a6"]
}

variable "SUBNET_IDS" {
  description = "A list of subnet IDs where the nodes/node groups will be provisioned"
  type        = list(string)
  default     = ["subnet-0d2671d84a3f5eb99", "subnet-06f2712e78e593152", "subnet-001ff98812a2e49e5", "subnet-066aca23688737c91", "subnet-0b42183b1df0e9061", "subnet-01b9abeeefc878fc4", "subnet-03225fc0c62f573b7", "subnet-01e2143c0b3d4f8a6"]
}

variable "API_PUBLIC" {
  description = "Enable/Disable public api endpoint for the cluster"
  type        = bool
  default     = true
}

variable "API_PRIVATE" {
  description = "Enable/Disable private api endpoint for the cluster"
  type        = bool
  default     = true
}

variable "TAINT_KEY" {
  description = "Default key for taints"
  type        = string
  default     = "workload"
}

variable "TAINT_EFFECT" {
  description = "Default effect for taints"
  type        = string
  default     = "NO_SCHEDULE"
}

variable "LABEL_KEY" {
  description = "Default key for node labels"
  type        = string
  default     = "workload"
}

variable "ROOT_VOL_CONFIG" {
  description = "This is the custom root disk config for nodegroups that need a larger disk size"
  type = object({
    device_name = string
    ebs = object({
      volume_size           = number
      volume_type           = string
      iops                  = number
      throughput            = number
      encrypted             = bool
      delete_on_termination = bool
    })
  })
  default = {
    device_name = "/dev/xvda"
    ebs = {
      volume_size           = 80
      volume_type           = "gp3"
      iops                  = 3000
      throughput            = 125
      encrypted             = true
      delete_on_termination = true
    }
  }
}

variable "DATA_VOL_CONFIG" {
  description = "This is the custom root disk config for nodegroups that need a larger disk size"
  type = object({
    device_name = string
    ebs = object({
      volume_size           = number
      volume_type           = string
      iops                  = number
      throughput            = number
      encrypted             = bool
      delete_on_termination = bool
    })
  })
  default = {
    device_name = "/dev/xvdb"
    ebs = {
      volume_size           = 50
      volume_type           = "gp3"
      iops                  = 3000
      throughput            = 125
      encrypted             = true
      delete_on_termination = true
    }
  }
}

variable "ADDON_CONFIG" {
  description = "Override default HYC addon config"
  type        = any
  default = {
    observability = {
      create = false
    }
    ebscsi = {
      create = true
    }
    efscsi = {
      create = true
    }
    lbc = {
      create = true
    }
    identity = {
      create = true
    }
    autoscaler = {
      create = true
    }
  }
}

variable "FARGATE_SELECTOR_NAMESPACE" {
  description = "Namespace of the pods to match in fargate"
  type        = string
  default     = "default"
}

variable "FARGATE_SELECTOR_LABELS" {
  description = "Labels of the pods to run on fargate"
  type        = map(string)
  default = {
    "infrastructure" = "fargate"
  }
}