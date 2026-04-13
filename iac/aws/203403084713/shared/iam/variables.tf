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

variable "DATAHUB_LFS_BUCKET_NAME" {
  description = "Name of the S3 bucket used for GitHub LFS storage"
  type        = string
  default     = "sc-203403084713-pp-4rxlzd426npxu-bucket-kswubqqre3jr"
}

variable "GITHUB_LFS_SECRET_NAME" {
  description = "Name of the Secrets Manager secret for GitHub LFS API keys"
  type        = string
  default     = "user-github-lfs-api-keys"
}