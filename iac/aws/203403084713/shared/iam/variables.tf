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

variable "DATABRICKS_UNITY_CATALOG_ROLE_ARN" {
  description = "ARN of the Databricks Unity Catalog master role that can assume the pipelines-databricks role"
  type        = string
  default     = "arn:aws:iam::414351767826:role/unity-catalog-prod-UCMasterRole-14S5ZJVKOTYTL"
}

variable "DATABRICKS_EXTERNAL_ID" {
  description = "External ID for the Databricks Unity Catalog trust relationship"
  type        = string
  default     = "2eaf52b2-1d9c-450e-8ecc-18fad034703b"
}

variable "LFS_PATH_PREFIX" {
  description = "S3 key prefix for LFS objects, excluded from Databricks pipeline access"
  type        = string
  default     = "lfs"
}