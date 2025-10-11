output "primary_endpoint" {
  description = "RDS primary instance endpoint"
  value       = aws_db_instance.primary.endpoint
}

output "primary_port" {
  description = "RDS primary instance port"
  value       = aws_db_instance.primary.port
}

output "replica_endpoint" {
  description = "RDS read replica endpoint"
  value       = aws_db_instance.replica.endpoint
}

output "replica_port" {
  description = "RDS read replica port"
  value       = aws_db_instance.replica.port
}

output "db_name" {
  description = "Database name"
  value       = aws_db_instance.primary.db_name
}

output "db_username" {
  description = "Database username"
  value       = aws_db_instance.primary.username
  sensitive   = true
}

output "secret_arn" {
  description = "ARN of the secret containing database password"
  value       = aws_secretsmanager_secret.db_password.arn
}