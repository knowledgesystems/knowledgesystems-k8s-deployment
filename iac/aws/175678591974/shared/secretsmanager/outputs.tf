output "rds_master_password_secret_arn" {
  description = "ARN of the shared RDS master password secret"
  value       = aws_secretsmanager_secret.user-oncokb-public-db-pw.arn
}

output "rds_master_password_secret_name" {
  description = "Name of the shared RDS master password secret"
  value       = aws_secretsmanager_secret.user-oncokb-public-db-pw.name
}
