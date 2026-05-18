ephemeral "aws_secretsmanager_secret_version" "rds_master_password" {
  secret_id = data.terraform_remote_state.secretsmanager.outputs.keycloak_db_password_secret_name
}

resource "aws_db_parameter_group" "keycloak_db" {
  name   = "${var.DB_INSTANCE_IDENTIFIER}-params"
  family = "mysql8.4"

  tags = {
    Name = "${var.DB_INSTANCE_IDENTIFIER}-params"
  }
}

resource "aws_db_instance" "keycloak_db" {
  identifier           = var.DB_INSTANCE_IDENTIFIER
  engine               = var.DB_ENGINE
  engine_version       = var.DB_ENGINE_VERSION
  instance_class       = var.DB_INSTANCE_CLASS
  username             = var.MASTER_USERNAME
  password_wo         = ephemeral.aws_secretsmanager_secret_version.rds_master_password.secret_string
  password_wo_version = data.terraform_remote_state.secretsmanager.outputs.keycloak_db_password_version
  port                 = 3306
  parameter_group_name = aws_db_parameter_group.keycloak_db.name

  multi_az            = false
  publicly_accessible = false

  allocated_storage = var.ALLOCATED_STORAGE
  storage_type      = var.STORAGE_TYPE
  storage_encrypted = var.STORAGE_ENCRYPTED
  kms_key_id        = var.KMS_KEY_ARN

  db_subnet_group_name   = var.DB_SUBNET_GROUP_NAME
  vpc_security_group_ids = var.VPC_SECURITY_GROUP_IDS

  backup_retention_period  = 7
  backup_window            = "06:14-06:44"
  maintenance_window       = "sun:07:24-sun:07:54"
  auto_minor_version_upgrade = true
  copy_tags_to_snapshot    = true
  deletion_protection      = false

  performance_insights_enabled = false
  skip_final_snapshot          = true

  tags = {
    Name             = var.DB_INSTANCE_IDENTIFIER
    "resource-name"  = var.DB_INSTANCE_IDENTIFIER
    "cdsi-app"       = "keycloak"
  }
}
