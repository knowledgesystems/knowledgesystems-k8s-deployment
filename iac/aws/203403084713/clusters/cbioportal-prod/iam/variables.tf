variable "cluster_oidc_provider_arn" {
  description = "The OIDC provider ARN for the EKS cluster"
  type        = string
}

variable "aws_region" {
  description = "AWS cli region"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "AWS eks cluster name"
  type        = string
}

variable "cbioportal_public_db_dump_bucket" {
  description = "S3 bucket name for cBioPortal public database weekly dumps"
  type        = string
  default     = "sc-203403084713-pp-jbeobuumvm3r4-bucket-rbgakorqrcyx"
}