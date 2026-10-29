variable "name" {
  description = "Prefix used for every resource name (project-environment)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the security groups are created"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block, used to allow DNS traffic to the VPC resolver"
  type        = string
}

variable "app_port" {
  description = "Port the application listens on"
  type        = number

  validation {
    condition     = var.app_port > 0 && var.app_port <= 65535
    error_message = "app_port must be a valid TCP port."
  }
}

variable "alb_ingress_cidrs" {
  description = "CIDR blocks allowed to reach the load balancer"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enable_https" {
  description = "Also open port 443 on the load balancer"
  type        = bool
  default     = false
}

variable "allowed_ssh_cidr" {
  description = "CIDR allowed to SSH into app instances. Null keeps SSH closed (SSM only)."
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional tags merged into every resource"
  type        = map(string)
  default     = {}
}
