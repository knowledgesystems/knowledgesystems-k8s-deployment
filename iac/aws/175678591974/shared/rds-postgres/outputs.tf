output "endpoint" {
  description = "Postgres host:port"
  value       = aws_db_instance.oncokb_postgres_db.endpoint
}

output "address" {
  description = "Postgres hostname"
  value       = aws_db_instance.oncokb_postgres_db.address
}

output "db_name" {
  value = aws_db_instance.oncokb_postgres_db.db_name
}

output "master_username" {
  value = aws_db_instance.oncokb_postgres_db.username
}
