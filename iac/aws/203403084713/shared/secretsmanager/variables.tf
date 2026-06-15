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

variable "GITHUB_LFS_CURATORS" {
  description = "List of curator names for GitHub LFS API key generation"
  type        = list(string)
  default     = ["nasirz1", "madupurr", "kundrar", "alhamadr", "satravab", "datahub", "leslie_gsoc"]
}

variable "KEYCLOAK_DB_PASSWORD_VERSION" {
  description = "Bump this to trigger a password rotation for keycloak-db"
  type        = number
  default     = 2
}

variable "K8S_AWS_CREDS_MANAGER_VALUE" {
  description = "JSON credentials for k8s-aws-creds-manager; supply only when rotating (bumping K8S_AWS_CREDS_MANAGER_VERSION)"
  type        = string
  ephemeral   = true
  default     = null
}

variable "K8S_AWS_CREDS_MANAGER_VERSION" {
  description = "Bump this to trigger a credential update for k8s-aws-creds-manager"
  type        = number
  default     = 2
}