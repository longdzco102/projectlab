variable "name" {
  description = "Prefix used for every resource name (project-environment)"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.small"
}

variable "private_subnet_ids" {
  description = "Private subnet IDs the ASG launches instances into"
  type        = list(string)
}

variable "app_security_group_id" {
  description = "Security group ID attached to the application instances"
  type        = string
}

variable "target_group_arn" {
  description = "Target group ARN the ASG registers instances into (null to skip)"
  type        = string
  default     = null
}

variable "min_size" {
  description = "Minimum ASG size"
  type        = number
  default     = 1
}

variable "desired_capacity" {
  description = "Desired ASG capacity"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum ASG size"
  type        = number
  default     = 3
}

variable "root_volume_size" {
  description = "Root EBS volume size in GB"
  type        = number
  default     = 30
}

variable "key_pair_name" {
  description = "Optional EC2 key pair name (null = SSM only)"
  type        = string
  default     = null
}

variable "ami_name_pattern" {
  description = "Ubuntu AMI name filter (Canonical owner 099720109477)"
  type        = string
  default     = "ubuntu/images/hvm-ssd*/ubuntu-noble-24.04-amd64-server-*"
}

variable "user_data" {
  description = "Optional cloud-init script (base64 encoded automatically)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Additional tags merged into every resource"
  type        = map(string)
  default     = {}
}
