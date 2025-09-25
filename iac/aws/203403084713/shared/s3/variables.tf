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

variable "S3_CDN_CERT_ARN" {
  description = "ARN of the AWS certificate to be used with S3 service catalog CDNs"
  type        = string
  default     = "arn:aws:acm:us-east-1:203403084713:certificate/b3a29c0f-0e1a-4b58-b4ba-32d38492a16a"
}