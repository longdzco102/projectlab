variable "name" {
  description = "Used for every resource name"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the public subnets, one per AZ"
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_cidrs) >= 2
    error_message = "At least two public subnets (two AZs) are required."
  }
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for the private subnets, one per AZ"
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_cidrs) >= 2
    error_message = "At least two private subnets (two AZs) are required for RDS."
  }

  validation {
    condition     = length(var.private_subnet_cidrs) == length(var.public_subnet_cidrs)
    error_message = "public_subnet_cidrs and private_subnet_cidrs must have the same length."
  }
}

variable "enable_nat_gateway" {
  description = "Create NAT gateway(s) so private subnets can reach the internet"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Create one shared NAT gateway instead of one per AZ (cheaper, not HA)"
  type        = bool
  default     = true
}

variable "enable_flow_logs" {
  description = "Publish VPC flow logs to CloudWatch Logs"
  type        = bool
  default     = false
}

variable "flow_logs_retention_days" {
  description = "Retention in days for the flow log group"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Additional tags merged into every resource"
  type        = map(string)
  default     = {}
}
