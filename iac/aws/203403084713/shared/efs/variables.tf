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
    cdsi-owner = "nasirz1@mskcc.org"
    cdsi-app   = "cbioportal"
    cdsi-team  = "data-visualization"
  }
}

variable "VPC_ID" {
  type    = string
  default = "vpc-0ee88fb9792a81d88"
}

variable "SUBNET_IDS" {
  type    = list(string)
  default = ["subnet-03225fc0c62f573b7", "subnet-0083625e4e09b8a64", "subnet-001ff98812a2e49e5", "subnet-00d0d72d18f9e67b3"]
}

