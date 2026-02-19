variable "GENOMENEXUS_EBS_VOLUME_AZ" {
  description = "Availability zone for the ebs volumes used in genome nexus mongodb helm chart."
  type        = string
  default     = "us-east-1b"
}