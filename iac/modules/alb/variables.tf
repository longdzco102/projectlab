variable "name" {
  description = "Prefix used for every resource name (project-environment)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID of the load balancer"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for the load balancer (at least two AZs)"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group ID attached to the load balancer"
  type        = string
}

variable "target_port" {
  description = "Port the target group forwards to on the instances"
  type        = number
}

variable "health_check_path" {
  description = "HTTP path used for target group health checks"
  type        = string
  default     = "/health"
}

variable "enable_https" {
  description = "Create an HTTPS listener and redirect HTTP to it"
  type        = bool
  default     = false
}

variable "certificate_arn" {
  description = "ACM certificate ARN (required when enable_https = true)"
  type        = string
  default     = null
}

variable "ssl_policy" {
  description = "TLS policy for the HTTPS listener"
  type        = string
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

variable "domain_name" {
  description = "Optional public DNS name for a Route53 alias record"
  type        = string
  default     = null
}

variable "route53_zone_id" {
  description = "Optional Route53 hosted zone ID for the alias record"
  type        = string
  default     = null
}

variable "access_logs_bucket" {
  description = "Existing S3 bucket for ALB access logs (null disables logging)"
  type        = string
  default     = null
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection on the load balancer"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags merged into every resource"
  type        = map(string)
  default     = {}
}
