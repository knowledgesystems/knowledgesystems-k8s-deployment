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

variable "DB_INSTANCE_IDENTIFIER" {
  description = "RDS DB instance identifier"
  type        = string
  default     = "keycloak-db-blue"
}

variable "DB_ENGINE" {
  description = "Database engine"
  type        = string
  default     = "mysql"
}

variable "DB_ENGINE_VERSION" {
  description = "Database engine version"
  type        = string
  default     = "8.4.9"
}

variable "DB_INSTANCE_CLASS" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.medium"
}

variable "MASTER_USERNAME" {
  description = "Master username for the DB instance"
  type        = string
  default     = "admin"
}

variable "ALLOCATED_STORAGE" {
  description = "Initial storage allocation in GiB"
  type        = number
  default     = 100
}

variable "STORAGE_TYPE" {
  description = "RDS storage type"
  type        = string
  default     = "gp3"
}

variable "STORAGE_ENCRYPTED" {
  description = "Enable storage encryption"
  type        = bool
  default     = true
}

variable "KMS_KEY_ARN" {
  description = "KMS key ARN for storage encryption"
  type        = string
  default     = "arn:aws:kms:us-east-1:666628074417:key/9633cd1e-292a-4f85-9d35-87082146f7ca"
}

variable "DB_SUBNET_GROUP_NAME" {
  description = "Name of existing DB subnet group"
  type        = string
  default     = "default-vpc-0003c8f263d7ed5ab"
}

variable "VPC_SECURITY_GROUP_IDS" {
  description = "List of VPC security group IDs for the RDS instance"
  type        = list(string)
  default     = ["sg-07aa5542845ee5a7f", "sg-0c0fb05897c65e2c3", "sg-08ec176db17fccbfa", "sg-0860b2f79d89cac9a", "sg-0b34e897f765fdb46"]
}