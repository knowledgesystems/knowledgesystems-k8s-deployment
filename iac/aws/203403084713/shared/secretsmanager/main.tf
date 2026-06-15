resource "random_id" "github_lfs_api_key" {
  for_each    = toset(var.GITHUB_LFS_CURATORS)
  byte_length = 32
}

resource "aws_secretsmanager_secret" "user-github-lfs-api-keys" {
  name        = "user-github-lfs-api-keys"
  description = "Curator API keys for GitHub LFS Lambda upload authentication"
}

resource "aws_secretsmanager_secret_version" "github-lfs-api-keys" {
  secret_id = aws_secretsmanager_secret.user-github-lfs-api-keys.id
  secret_string = jsonencode({
    for curator in var.GITHUB_LFS_CURATORS :
    curator => random_id.github_lfs_api_key[curator].hex
  })
}

ephemeral "random_password" "keycloak_db_pw" {
  length           = 16
  override_special = "!#$%^&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "keycloak_db_pw" {
  name        = "user-keycloak-db-blue-pw"
  description = "RDS master password for keycloak-db-blue"
}

resource "aws_secretsmanager_secret_version" "keycloak_db_pw" {
  secret_id                = aws_secretsmanager_secret.keycloak_db_pw.id
  secret_string_wo         = ephemeral.random_password.keycloak_db_pw.result
  secret_string_wo_version = var.KEYCLOAK_DB_PASSWORD_VERSION
}

resource "aws_secretsmanager_secret" "k8s_aws_creds_manager" {
  name        = "user-k8s-aws-creds-manager"
  description = "Service account credentials for multiple AWS accounts used by the K8s group"
}

ephemeral "aws_secretsmanager_secret_version" "k8s_aws_creds_manager_current" {
  secret_id = aws_secretsmanager_secret.k8s_aws_creds_manager.id
}

resource "aws_secretsmanager_secret_version" "k8s_aws_creds_manager" {
  secret_id                = aws_secretsmanager_secret.k8s_aws_creds_manager.id
  secret_string_wo         = coalesce(var.K8S_AWS_CREDS_MANAGER_VALUE, ephemeral.aws_secretsmanager_secret_version.k8s_aws_creds_manager_current.secret_string)
  secret_string_wo_version = var.K8S_AWS_CREDS_MANAGER_VERSION
}