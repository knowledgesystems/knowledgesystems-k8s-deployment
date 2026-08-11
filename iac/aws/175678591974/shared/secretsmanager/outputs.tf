output "rds_master_password_secret_arn" {
  description = "ARN of the shared RDS master password secret"
  value       = aws_secretsmanager_secret.user-oncokb-public-db-pw.arn
}

output "rds_master_password_secret_name" {
  description = "Name of the shared RDS master password secret"
  value       = aws_secretsmanager_secret.user-oncokb-public-db-pw.name
}

output "acgc_aws_creds_manager_secret_arn" {
  description = "ARN of ACGC's Bedrock creds-refresher SAML login secret"
  value       = aws_secretsmanager_secret.user-acgc-aws-creds-manager.arn
}
