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

variable "DATABRICKS_UNITY_CATALOG_ROLE_ARN" {
  description = "ARN of the Databricks Unity Catalog master role that can assume this role"
  type        = string
  default     = "arn:aws:iam::414351767826:role/unity-catalog-prod-UCMasterRole-14S5ZJVKOTYTL"
}

variable "DATABRICKS_EXTERNAL_IDS" {
  description = "External IDs for the Databricks trust relationship"
  type        = list(string)
  default     = ["d702e0b7-689c-4c82-9e12-fc0c444e2bd7", "68d58679-24ba-47ad-b403-a18946bd1f71"]
}

variable "DATABRICKS_S3_BUCKETS" {
  description = "List of S3 bucket names for Databricks access"
  type        = list(string)
  default = [
    "pdm-databricks",
    "cdm-data-databricks",
    "pdm-data-databricks",
    "msk-impact-databricks",
    "mskmind-nb-databricks",
    "*databricks*"
  ]
}