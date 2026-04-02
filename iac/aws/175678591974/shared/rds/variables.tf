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

variable "VPC_ID" {
  description = "VPC id for the RDS instance"
  type        = string
  default     = "vpc-05a4d60569b764779"
}

variable "SUBNET_IDS" {
  description = "Public subnets for the RDS subnet group"
  type        = list(string)
  default     = ["subnet-0f814b811374c05e8", "subnet-00347c38f00ad8944", "subnet-044ac65e48ee7baa8", "subnet-0454403b8778da308"]
}

variable "DB_INSTANCE_IDENTIFIER" {
  description = "RDS DB instance identifier"
  type        = string
  default     = "oncokb-public-db"
}

variable "DB_NAME" {
  description = "Initial database name. Leave null to match the current instance."
  type        = string
  default     = null
  nullable    = true
}

variable "DB_ENGINE" {
  description = "Database engine"
  type        = string
  default     = "mysql"
}

variable "DB_ENGINE_VERSION" {
  description = "Database engine version"
  type        = string
  default     = "8.0.42"
}

variable "DB_INSTANCE_CLASS" {
  description = "RDS instance class"
  type        = string
  default     = "db.t4g.xlarge"
}

variable "MASTER_USERNAME" {
  description = "Master username for the DB instance"
  type        = string
  default     = "admin"
}

variable "MASTER_PASSWORD" {
  description = "Master password for the DB instance"
  type        = string
  sensitive   = true
}

variable "PUBLICLY_ACCESSIBLE" {
  description = "Make the RDS instance publicly accessible"
  type        = bool
  default     = true
}

variable "ALLOCATED_STORAGE" {
  description = "Initial storage allocation in GiB"
  type        = number
  default     = 200
}

variable "MAX_ALLOCATED_STORAGE" {
  description = "Maximum autoscaled storage allocation in GiB"
  type        = number
  default     = 1000
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

variable "KMS_KEY_ID" {
  description = "KMS alias name for storage encryption"
  type        = string
  default     = "alias/aws/rds"
}
