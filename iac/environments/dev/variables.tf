###############################################################################
# General
###############################################################################

variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "ap-southeast-1"
}

variable "project_name" {
  description = "Project name, used as prefix for every resource name"
  type        = string
  default     = "xianxia-chat"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,20}$", var.project_name))
    error_message = "project_name must be 2-21 chars, lowercase letters, digits or hyphens, starting with a letter."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

###############################################################################
# Networking
###############################################################################

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the public subnets (one per AZ)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for the private subnets (one per AZ, minimum 2 for RDS)"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "single_nat_gateway" {
  description = "Use a single NAT gateway (cheaper, not HA). Set false for production."
  type        = bool
  default     = true
}

variable "enable_vpc_flow_logs" {
  description = "Send VPC flow logs to CloudWatch Logs"
  type        = bool
  default     = false
}

variable "flow_logs_retention_days" {
  description = "Retention of the VPC flow log group"
  type        = number
  default     = 30
}

###############################################################################
# Compute
###############################################################################

variable "instance_type" {
  description = "EC2 instance type for the application ASG"
  type        = string
  default     = "t3.small"
}

variable "asg_min_size" {
  description = "Minimum number of application instances"
  type        = number
  default     = 1
}

variable "asg_desired_capacity" {
  description = "Desired number of application instances"
  type        = number
  default     = 1
}

variable "asg_max_size" {
  description = "Maximum number of application instances"
  type        = number
  default     = 3
}

variable "root_volume_size" {
  description = "Root EBS volume size in GB"
  type        = number
  default     = 30
}

variable "key_pair_name" {
  description = "Optional EC2 key pair. Leave null to rely on SSM Session Manager only."
  type        = string
  default     = null
}

variable "user_data" {
  description = "Optional cloud-init script executed on first boot"
  type        = string
  default     = ""
}

###############################################################################
# Application / load balancer
###############################################################################

variable "app_port" {
  description = "Port the application listens on inside the instances"
  type        = number
  default     = 3000
}

variable "health_check_path" {
  description = "HTTP path used by the target group health check"
  type        = string
  default     = "/health"
}

variable "allowed_ssh_cidr" {
  description = "CIDR allowed to SSH into app instances. Null disables SSH entirely (SSM only)."
  type        = string
  default     = null
}

###############################################################################
# TLS / DNS
###############################################################################

variable "enable_https" {
  description = "Create an HTTPS listener (requires certificate_arn)"
  type        = bool
  default     = false
}

variable "certificate_arn" {
  description = "ACM certificate ARN for the HTTPS listener"
  type        = string
  default     = null
}

variable "domain_name" {
  description = "Public DNS name pointing at the ALB (optional)"
  type        = string
  default     = null
}

variable "route53_zone_id" {
  description = "Route53 hosted zone ID used to create the alias record (optional)"
  type        = string
  default     = null
}

variable "alb_access_logs_bucket" {
  description = "Existing S3 bucket for ALB access logs. Null disables access logging."
  type        = string
  default     = null
}

###############################################################################
# Database
###############################################################################

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Initial RDS storage in GB"
  type        = number
  default     = 20
}

variable "db_max_allocated_storage" {
  description = "Upper limit for RDS storage autoscaling in GB (0 disables it)"
  type        = number
  default     = 100
}

variable "db_engine_version" {
  description = "PostgreSQL engine version (major or major.minor)"
  type        = string
  default     = "16"
}

variable "db_name" {
  description = "Initial database name"
  type        = string
  default     = "webchat"
}

variable "db_master_username" {
  description = "RDS master username. The password is managed by Secrets Manager."
  type        = string
  default     = "dbadmin"
}

variable "db_multi_az" {
  description = "Run RDS in Multi-AZ mode"
  type        = bool
  default     = false
}

variable "db_backup_retention_period" {
  description = "RDS automated backup retention in days"
  type        = number
  default     = 7
}

variable "db_deletion_protection" {
  description = "Block deletion of the RDS instance"
  type        = bool
  default     = false
}

variable "db_skip_final_snapshot" {
  description = "Skip the final snapshot when the DB is destroyed"
  type        = bool
  default     = true
}

variable "db_final_snapshot_identifier" {
  description = "Final snapshot name. Required when db_skip_final_snapshot = false and must be unique."
  type        = string
  default     = null
}

variable "db_performance_insights_enabled" {
  description = "Enable Performance Insights (requires an instance class that supports it)"
  type        = bool
  default     = false
}
