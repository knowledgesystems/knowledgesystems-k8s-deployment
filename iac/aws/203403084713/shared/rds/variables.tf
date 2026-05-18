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
  default     = "db.t3.micro"
}

variable "MASTER_USERNAME" {
  description = "Master username for the DB instance"
  type        = string
  default     = "admin"
}

variable "ALLOCATED_STORAGE" {
  description = "Initial storage allocation in GiB"
  type        = number
  default     = 20
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
  default     = "arn:aws:kms:us-east-1:070278699608:key/mrk-765df2ddf163483c870929a1f545dcc5"
}

variable "DB_SUBNET_GROUP_NAME" {
  description = "Name of existing DB subnet group"
  type        = string
  default     = "default-vpc-0ee88fb9792a81d88"
}

variable "VPC_SECURITY_GROUP_IDS" {
  description = "List of VPC security group IDs for the RDS instance"
  type        = list(string)
  default     = ["sg-03a6b8b7bda27be0b", "sg-0ddf0605a0294d65d"]
}