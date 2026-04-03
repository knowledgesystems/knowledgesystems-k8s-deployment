data "aws_vpc" "oncokb_research_vpc" {
  id = var.VPC_ID
}

data "aws_kms_alias" "rds" {
  name = var.KMS_KEY_ID
}

data "aws_secretsmanager_secret" "rds_master_password" {
  name = var.MASTER_PASSWORD_SECRET_NAME
}

data "aws_secretsmanager_secret_version" "rds_master_password" {
  secret_id = data.aws_secretsmanager_secret.rds_master_password.id
}

resource "aws_security_group" "oncokb_public_db_sg" {
  name        = "${var.DB_INSTANCE_IDENTIFIER}-sg"
  description = "Security group for ${var.DB_INSTANCE_IDENTIFIER}"
  vpc_id      = var.VPC_ID

  tags = {
    Name = "${var.DB_INSTANCE_IDENTIFIER}-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "oncokb_public_db_ingress" {
  ip_protocol       = "tcp"
  security_group_id = aws_security_group.oncokb_public_db_sg.id
  from_port         = 3306
  to_port           = 3306
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Allow MySQL access from anywhere over IPv4"

  tags = {
    Name = "RDS MySQL Ingress"
  }
}

resource "aws_vpc_security_group_ingress_rule" "oncokb_public_db_ingress_ipv6" {
  ip_protocol       = "tcp"
  security_group_id = aws_security_group.oncokb_public_db_sg.id
  from_port         = 3306
  to_port           = 3306
  cidr_ipv6         = "::/0"
  description       = "Allow MySQL access from anywhere over IPv6"

  tags = {
    Name = "RDS MySQL Ingress IPv6"
  }
}

resource "aws_vpc_security_group_egress_rule" "oncokb_public_db_egress" {
  ip_protocol       = -1
  security_group_id = aws_security_group.oncokb_public_db_sg.id
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_db_subnet_group" "oncokb_public_db" {
  name       = "${var.DB_INSTANCE_IDENTIFIER}-subnet-group"
  subnet_ids = var.SUBNET_IDS

  tags = {
    Name = "${var.DB_INSTANCE_IDENTIFIER}-subnet-group"
  }
}

resource "aws_db_instance" "oncokb_public_db" {
  identifier           = var.DB_INSTANCE_IDENTIFIER
  db_name              = var.DB_NAME
  engine               = var.DB_ENGINE
  engine_version       = var.DB_ENGINE_VERSION
  instance_class       = var.DB_INSTANCE_CLASS
  username             = var.MASTER_USERNAME
  password             = data.aws_secretsmanager_secret_version.rds_master_password.secret_string
  port                 = 3306
  parameter_group_name = "default.mysql8.0"
  option_group_name    = "default:mysql-8-0"

  multi_az            = false
  publicly_accessible = var.PUBLICLY_ACCESSIBLE

  allocated_storage     = var.ALLOCATED_STORAGE
  max_allocated_storage = var.MAX_ALLOCATED_STORAGE
  storage_type          = var.STORAGE_TYPE
  storage_encrypted     = var.STORAGE_ENCRYPTED
  kms_key_id            = data.aws_kms_alias.rds.target_key_arn

  db_subnet_group_name   = aws_db_subnet_group.oncokb_public_db.name
  vpc_security_group_ids = [aws_security_group.oncokb_public_db_sg.id]

  database_insights_mode                = "standard"
  performance_insights_enabled          = true
  performance_insights_retention_period = 7
  skip_final_snapshot                   = true

  tags = {
    Name = var.DB_INSTANCE_IDENTIFIER
  }
}
