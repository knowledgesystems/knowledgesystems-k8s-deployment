variable "AWS_PROFILE" {
  description = "AWS CLI profile for the cBioPortal dev account."
  type        = string
  ephemeral   = true
  default     = "dev"
}

variable "instance_type" {
  description = "ARM instance size for the cloud-model gateway. This is a new instance, separate from hermes-agent-node."
  type        = string
  default     = "m8g.large"

  validation {
    condition     = contains(["m8g.medium", "m8g.large", "m8g.xlarge"], var.instance_type)
    error_message = "Use an ARM m8g size compatible with the deployment AMI."
  }
}

variable "ami_id" {
  description = "Pinned Amazon Linux 2023 ARM64 AMI in us-east-1."
  type        = string
  default     = "ami-00f80eba068753881"
}

variable "key_name" {
  description = "Existing dev-account SSH key pair used to access the new node."
  type        = string
  default     = "hermes-agent-node-key"
}
