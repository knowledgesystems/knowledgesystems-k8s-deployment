output "github_lfs_api_keys" {
  description = "Generated API keys for GitHub LFS curators"
  value = {
    for curator in var.GITHUB_LFS_CURATORS :
    curator => random_id.github_lfs_api_key[curator].hex
  }
  sensitive = true
}

output "keycloak_db_password_secret_arn" {
  description = "ARN of the keycloak-db-blue RDS master password secret"
  value       = aws_secretsmanager_secret.keycloak_db_pw.arn
}

output "keycloak_db_password_secret_name" {
  description = "Name of the keycloak-db-blue RDS master password secret"
  value       = aws_secretsmanager_secret.keycloak_db_pw.name
}

output "keycloak_db_password_version" {
  description = "Current password rotation version for keycloak-db-blue"
  value       = var.KEYCLOAK_DB_PASSWORD_VERSION
}
