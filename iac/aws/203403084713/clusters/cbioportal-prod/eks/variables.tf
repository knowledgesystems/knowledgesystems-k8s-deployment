variable "AWS_PROFILE" {
  description = "AWS cli profile"
  type        = string
  ephemeral   = true
  default     = "default"
}

variable "TAINT_KEY" {
  description = "Default key for taints"
  type        = string
  default     = "workload"
}

variable "TAINT_EFFECT" {
  description = "Default effect for taints"
  type        = string
  default     = "NO_SCHEDULE"
}