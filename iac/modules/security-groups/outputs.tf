output "alb_security_group_id" {
  description = "Security group ID of the load balancer"
  value       = aws_security_group.alb.id
}

output "app_security_group_id" {
  description = "Security group ID of the application instances"
  value       = aws_security_group.app.id
}

output "db_security_group_id" {
  description = "Security group ID of the database"
  value       = aws_security_group.db.id
}
