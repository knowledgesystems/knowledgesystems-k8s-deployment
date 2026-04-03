resource "random_password" "oncokb-public-db-pw" {
  count            = 1
  length           = 16
  special          = true
  override_special = "!#$%^&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "user-oncokb-public-db-pw" {
  name        = "user-oncokb-public-db-pw"
  description = "RDS master password for oncokb-public-db"
}

resource "aws_secretsmanager_secret_version" "oncokb-public-db-pw" {
  secret_id     = aws_secretsmanager_secret.user-oncokb-public-db-pw.id
  secret_string = random_password.oncokb-public-db-pw[0].result
}
