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

variable "ACGC_AWS_CREDS_MANAGER_VALUE" {
  description = "JSON SAML login creds for ACGC's Bedrock credential refresher; supply only when rotating (bumping ACGC_AWS_CREDS_MANAGER_VERSION)"
  type        = string
  ephemeral   = true
  default     = null
}

variable "ACGC_AWS_CREDS_MANAGER_VERSION" {
  description = "Bump this to trigger a credential update for user-acgc-aws-creds-manager"
  type        = number
  default     = 1
}
