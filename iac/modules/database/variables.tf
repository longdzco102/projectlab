variable "name" {
  description = "Prefix used for every resource name (project-environment)"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for the DB subnet group (at least two AZs)"
  type        = list(string)
}

variable "db_security_group_id" {
  description = "Security group ID attached to the database"
  type        = string
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Initial storage in GB"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Upper limit for storage autoscaling in GB (0 disables autoscaling)"
  type        = number
  default     = 100
}

variable "engine_version" {
  description = "PostgreSQL version, major (16) or major.minor (16.4)"
  type        = string
  default     = "16"
}

variable "db_name" {
  description = "Initial database name"
  type        = string
  default     = "webchat"
}

variable "master_username" {
  description = "Master username; the password is generated and stored in Secrets Manager"
  type        = string
  default     = "dbadmin"
}

variable "multi_az" {
  description = "Run the database in Multi-AZ mode"
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "Automated backup retention in days (0 disables backups)"
  type        = number
  default     = 7
}

variable "deletion_protection" {
  description = "Block deletion of the database"
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Skip the final snapshot on destroy"
  type        = bool
  default     = true
}

variable "final_snapshot_identifier" {
  description = "Final snapshot name; required when skip_final_snapshot = false"
  type        = string
  default     = null
}

variable "apply_immediately" {
  description = "Apply changes immediately instead of during the maintenance window"
  type        = bool
  default     = false
}

variable "monitoring_interval" {
  description = "Enhanced Monitoring interval in seconds (0 disables it)"
  type        = number
  default     = 60

  validation {
    condition     = contains([0, 1, 5, 10, 15, 30, 60], var.monitoring_interval)
    error_message = "monitoring_interval must be one of 0, 1, 5, 10, 15, 30 or 60."
  }
}

variable "performance_insights_enabled" {
  description = "Enable Performance Insights (not supported by every small instance class)"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags merged into every resource"
  type        = map(string)
  default     = {}
}
