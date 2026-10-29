locals {
  name = "${var.project_name}-${var.environment}"
}

# Fail early (and clearly) on inconsistent inputs instead of at apply time.
check "https_requires_certificate" {
  assert {
    condition     = !var.enable_https || var.certificate_arn != null
    error_message = "enable_https = true requires certificate_arn to be set."
  }
}

check "dns_record_pair" {
  assert {
    condition     = (var.domain_name == null) == (var.route53_zone_id == null)
    error_message = "Set both domain_name and route53_zone_id, or neither of them."
  }
}

module "networking" {
  source = "../../modules/networking"

  name                     = local.name
  vpc_cidr                 = var.vpc_cidr
  public_subnet_cidrs      = var.public_subnet_cidrs
  private_subnet_cidrs     = var.private_subnet_cidrs
  single_nat_gateway       = var.single_nat_gateway
  enable_flow_logs         = var.enable_vpc_flow_logs
  flow_logs_retention_days = var.flow_logs_retention_days
}

module "security_groups" {
  source = "../../modules/security-groups"

  name              = local.name
  vpc_id            = module.networking.vpc_id
  vpc_cidr          = module.networking.vpc_cidr
  app_port          = var.app_port
  alb_ingress_cidrs = ["0.0.0.0/0"]
  enable_https      = var.enable_https
  allowed_ssh_cidr  = var.allowed_ssh_cidr
}

module "alb" {
  source = "../../modules/alb"

  name                       = local.name
  vpc_id                     = module.networking.vpc_id
  public_subnet_ids          = module.networking.public_subnet_ids
  security_group_id          = module.security_groups.alb_security_group_id
  target_port                = var.app_port
  health_check_path          = var.health_check_path
  enable_https               = var.enable_https
  certificate_arn            = var.certificate_arn
  domain_name                = var.domain_name
  route53_zone_id            = var.route53_zone_id
  access_logs_bucket         = var.alb_access_logs_bucket
  enable_deletion_protection = var.environment == "prod"
}

module "compute" {
  source = "../../modules/compute"

  name                  = local.name
  instance_type         = var.instance_type
  private_subnet_ids    = module.networking.private_subnet_ids
  app_security_group_id = module.security_groups.app_security_group_id
  target_group_arn      = module.alb.target_group_arn
  min_size              = var.asg_min_size
  desired_capacity      = var.asg_desired_capacity
  max_size              = var.asg_max_size
  root_volume_size      = var.root_volume_size
  key_pair_name         = var.key_pair_name
  user_data             = var.user_data
}

module "database" {
  source = "../../modules/database"

  name                         = local.name
  private_subnet_ids           = module.networking.private_subnet_ids
  db_security_group_id         = module.security_groups.db_security_group_id
  instance_class               = var.db_instance_class
  allocated_storage            = var.db_allocated_storage
  max_allocated_storage        = var.db_max_allocated_storage
  engine_version               = var.db_engine_version
  db_name                      = var.db_name
  master_username              = var.db_master_username
  multi_az                     = var.db_multi_az
  backup_retention_period      = var.db_backup_retention_period
  deletion_protection          = var.db_deletion_protection
  skip_final_snapshot          = var.db_skip_final_snapshot
  final_snapshot_identifier    = var.db_final_snapshot_identifier
  performance_insights_enabled = var.db_performance_insights_enabled
}
