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
  default     = "vpc-0003c8f263d7ed5ab"
}

variable "CONTROL_PLANE_SUBNET_IDS" {
  description = "A list of subnet IDs where the EKS cluster control plane (ENIs) will be provisioned"
  type        = list(string)
  default     = ["subnet-081312133f83ddd2b", "subnet-0a385961f1753ea69", "subnet-0917a96517f3dad1d"]
}

variable "SUBNET_IDS" {
  description = "A list of subnet IDs where the nodes/node groups will be provisioned"
  type        = list(string)
  default     = ["subnet-081312133f83ddd2b", "subnet-0a385961f1753ea69", "subnet-0917a96517f3dad1d"]
}

variable "API_PUBLIC" {
  description = "Enable/Disable public api endpoint for the cluster"
  type        = bool
  default     = true
}

variable "API_PRIVATE" {
  description = "Enable/Disable private api endpoint for the cluster"
  type        = bool
  default     = false
}

variable "LABEL_KEY" {
  description = "Default key for node labels"
  type        = string
  default     = "workload"
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