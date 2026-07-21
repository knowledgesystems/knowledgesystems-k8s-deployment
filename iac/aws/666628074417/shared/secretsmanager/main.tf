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