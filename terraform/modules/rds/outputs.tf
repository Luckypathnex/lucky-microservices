output "db_endpoint" {
  description = "Database endpoint address"
  value       = try(aws_db_instance.main[0].endpoint, null)
}

output "db_name" {
  description = "Database name"
  value       = var.db_name
}

output "db_username" {
  description = "Database master username"
  value       = var.db_username
  sensitive   = true
}

output "db_password" {
  description = "Database master password"
  value       = random_password.db_password.result
  sensitive   = true
}

output "db_security_group_id" {
  description = "RDS security group ID"
  value       = aws_security_group.rds.id
}