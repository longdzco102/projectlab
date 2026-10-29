output "db_instance_id" {
  description = "RDS instance identifier"
  value       = aws_db_instance.this.id
}

output "address" {
  description = "RDS hostname"
  value       = aws_db_instance.this.address
}

output "endpoint" {
  description = "RDS connection endpoint (host:port)"
  value       = aws_db_instance.this.endpoint
}

output "port" {
  description = "RDS port"
  value       = aws_db_instance.this.port
}

output "db_name" {
  description = "Initial database name"
  value       = aws_db_instance.this.db_name
}

output "master_user_secret_arn" {
  description = "ARN of the Secrets Manager secret holding the master credentials"
  value       = try(aws_db_instance.this.master_user_secret[0].secret_arn, null)
}

output "parameter_group_name" {
  description = "Custom parameter group name"
  value       = aws_db_parameter_group.this.name
}
