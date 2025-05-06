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
  default     = "oncokb-dev"
}

variable "CLUSTER_VER" {
  description = "Kubernetes version of the cluster"
  type        = string
  default     = "1.30"
}

variable "CLUSTER_ENV" {
  description = "Environment value for the cluster [prod | dev]"
  type        = string
  default     = "dev"
}

variable "VPC_ID" {
  description = "VPC id for the cluster"
  type        = string
  default     = "vpc-08330c6eeb2de84b1"
}

variable "VPC_AZ" {
  description = "Availability zones from the VPC"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
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