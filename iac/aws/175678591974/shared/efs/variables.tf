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
  description = "Set of default tags that get added to all resources"
  type        = map(string)
  default = {
    cdsi-owner = "luc2@mskcc.org"
    cdsi-app   = "oncokb"
    cdsi-team  = "oncokb"
  }
}

variable "VPC_ID" {
  type    = string
  default = "vpc-05a4d60569b764779"
}

variable "SUBNET_IDS" {
  type    = list(string)
  default = ["subnet-0f12260d835e34eaa", "subnet-0e33028044f5134d0", "subnet-0dce8bb1a75d09101", "subnet-0605f2e69906444e1"]
}
