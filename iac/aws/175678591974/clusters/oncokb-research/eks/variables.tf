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
    cdsi-owner = "luc2@mskcc.org"
    cdsi-app   = "oncokb"
    cdsi-team  = "oncokb"
  }
}

variable "CLUSTER_NAME" {
  description = "Name of the cluster"
  type        = string
  default     = "oncokb-research"
}

variable "CLUSTER_VER" {
  description = "Kubernetes version of the cluster"
  type        = string
  default     = "1.35"
}

variable "NODEGROUP_VER" {
  description = "Kubernetes version of the nodegroups"
  type        = string
  default     = "1.35"
}

variable "CLUSTER_ENV" {
  description = "Environment value for the cluster [prod | dev]"
  type        = string
  default     = "prod"
}

variable "VPC_ID" {
  description = "VPC id for the cluster"
  type        = string
  default     = "vpc-05a4d60569b764779"
}

variable "CONTROL_PLANE_SUBNET_IDS" {
  description = "A list of subnet IDs where the EKS cluster control plane (ENIs) will be provisioned"
  type        = list(string)
  default     = ["subnet-0e33028044f5134d0", "subnet-052be58811b6d6044", "subnet-0dce8bb1a75d09101", "subnet-0a7f575560560b136", "subnet-0605f2e69906444e1", "subnet-01150e7112702982c", "subnet-0d1cffd912caaf393", "subnet-0f12260d835e34eaa"]
}

variable "SUBNET_IDS" {
  description = "A list of subnet IDs where the nodes/node groups will be provisioned"
  type        = list(string)
  default     = ["subnet-0e33028044f5134d0", "subnet-052be58811b6d6044", "subnet-0dce8bb1a75d09101", "subnet-0a7f575560560b136", "subnet-0605f2e69906444e1", "subnet-01150e7112702982c", "subnet-0d1cffd912caaf393", "subnet-0f12260d835e34eaa"]
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
