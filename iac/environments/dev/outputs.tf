###############################################################################
# Application entry point
###############################################################################

output "app_url" {
  description = "Public URL of the application"
  value       = module.alb.url
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.alb.dns_name
}

output "alb_zone_id" {
  description = "Hosted zone ID of the ALB (for external DNS records)"
  value       = module.alb.zone_id
}

output "asg_name" {
  description = "Auto Scaling group name of the application tier"
  value       = module.compute.asg_name
}

output "ami_id" {
  description = "AMI resolved for the application instances"
  value       = module.compute.ami_id
}

###############################################################################
# Access
###############################################################################

output "ssm_session_command" {
  description = "Open a shell on a running instance through SSM Session Manager"
  value = join(" ", [
    "aws ssm start-session --target $(aws autoscaling describe-auto-scaling-groups",
    "--auto-scaling-group-names ${module.compute.asg_name}",
    "--query 'AutoScalingGroups[0].Instances[0].InstanceId' --output text)"
  ])
}

output "ssh_command" {
  description = "SSH command (only works when allowed_ssh_cidr and key_pair_name are set)"
  value = var.allowed_ssh_cidr == null || var.key_pair_name == null ? null : join(" ", [
    "aws ssm start-session --target $(aws autoscaling describe-auto-scaling-groups",
    "--auto-scaling-group-names ${module.compute.asg_name}",
    "--query 'AutoScalingGroups[0].Instances[0].InstanceId' --output text)",
    "--document-name AWS-StartSSHSession --parameters portNumber=22"
  ])
}

###############################################################################
# Database
###############################################################################

output "db_address" {
  description = "RDS hostname (reachable only from inside the VPC)"
  value       = module.database.address
}

output "db_port" {
  description = "RDS port"
  value       = module.database.port
}

output "db_name" {
  description = "Initial database name"
  value       = module.database.db_name
}

output "db_master_user_secret_arn" {
  description = "ARN of the Secrets Manager secret holding the master credentials"
  value       = module.database.master_user_secret_arn
}

###############################################################################
# Networking
###############################################################################

output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs (application and database tier)"
  value       = module.networking.private_subnet_ids
}

output "public_subnet_ids" {
  description = "Public subnet IDs (load balancer tier)"
  value       = module.networking.public_subnet_ids
}
