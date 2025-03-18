variable "AWS_PROFILE" {
  description = "AWS cli profile"
  type        = string
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
    cdsi-owner = "hweej@mskcc.org"
    cdsi-app   = "scope-portal"
    cdsi-team  = "data-visualization"
  }
}

variable "bucket_prefix" {
  type        = string
  description = "The name prefix used for creating a globally unique bucket name."
  nullable    = false

  validation {
    condition     = length(var.bucket_prefix) <= 36 && can(regex("^[a-z0-9][a-z0-9.-]+", var.bucket_prefix)) && !can(regex("\\.\\.", var.bucket_prefix))
    error_message = "The bucket_prefix must 36 characeters or less and match the regular expression: /^[a-z0-9][a-z0-9.-]+/"
  }
}

variable "force_destroy" {
  type        = bool
  description = "Boolean that indicates all objects (including any locked objects) should be deleted from the bucket when the bucket is destroyed so that the bucket can be destroyed without error. These objects are not recoverable."
  default     = false
  nullable    = false
}

variable "org_readers" {
  type = list(object({
    arn = string,
  }))
  description = "Principals within the MSKCC AWS Organization who have read permissions on the bucket."
  default     = []
  nullable    = false
}


variable "org_writers" {
  type        = list(string)
  description = "Principals within the MSKCC AWS Organization who have write permissions on the bucket."
  default     = []
  nullable    = false

}

variable "external_writers" {
  description = "Principals outside the MSKCC AWS Organization who have write permissions on the bucket."
  type = list(object({
    account_id  = string,
    external_id = string,
  }))
  default = []
}

variable "tags" {
  type        = map(string)
  description = "Additional tags to add to the S3 bucket. By default, the module will add application-id, application, cost-center, env, service, version, and owner-email"
  default     = {}
  nullable    = false
}

variable "classification" {
  type        = string
  description = "The data classification of objects stored in this bucket."
  nullable    = false
  default     = "restricted"

  validation {
    condition = contains([
      "protected",
      "confidential",
      "restricted",
      "public",
      ],
    var.classification)
    error_message = "The classificaiton must be one of: (protected|confidential|restricted|public))"
  }
}


