locals {
  # "16" -> "postgres16", "16.4" -> "postgres16"
  major_version          = split(".", var.engine_version)[0]
  parameter_group_family = "postgres${local.major_version}"
}

check "final_snapshot" {
  assert {
    condition     = var.skip_final_snapshot || var.final_snapshot_identifier != null
    error_message = "final_snapshot_identifier must be set when skip_final_snapshot = false."
  }
}

###############################################################################
# Networking + configuration
###############################################################################

resource "aws_db_subnet_group" "this" {
  name       = "${var.name}-db-subnets"
  subnet_ids = var.private_subnet_ids

  tags = merge(var.tags, {
    Name = "${var.name}-db-subnets"
  })
}

resource "aws_db_parameter_group" "this" {
  name_prefix = "${var.name}-pg${local.major_version}-"
  family      = local.parameter_group_family
  description = "Custom PostgreSQL ${local.major_version} parameters for ${var.name}"

  parameter {
    name  = "log_min_duration_statement"
    value = "1000"
  }

  parameter {
    name         = "log_connections"
    value        = "1"
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "log_disconnections"
    value        = "1"
    apply_method = "pending-reboot"
  }

  tags = merge(var.tags, {
    Name = "${var.name}-pg${local.major_version}"
  })
}

###############################################################################
# Enhanced Monitoring role
###############################################################################

data "aws_iam_policy_document" "monitoring_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "monitoring" {
  count = var.monitoring_interval > 0 ? 1 : 0

  name               = "${var.name}-rds-monitoring"
  description        = "Allows RDS to publish Enhanced Monitoring metrics"
  assume_role_policy = data.aws_iam_policy_document.monitoring_assume.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "monitoring" {
  count = var.monitoring_interval > 0 ? 1 : 0

  role       = aws_iam_role.monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

###############################################################################
# Database instance
###############################################################################

resource "aws_db_instance" "this" {
  identifier     = "${var.name}-db"
  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class

  db_name                     = var.db_name
  username                    = var.master_username
  manage_master_user_password = true
  parameter_group_name        = aws_db_parameter_group.this.name
  db_subnet_group_name        = aws_db_subnet_group.this.name
  vpc_security_group_ids      = [var.db_security_group_id]
  publicly_accessible         = false
  auto_minor_version_upgrade  = true

  # Storage
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true

  # Availability / backups
  multi_az                = var.multi_az
  backup_retention_period = var.backup_retention_period
  backup_window           = "03:00-04:00"
  maintenance_window      = "sun:04:30-sun:05:30"
  copy_tags_to_snapshot   = true

  # Observability
  monitoring_interval                   = var.monitoring_interval
  monitoring_role_arn                   = var.monitoring_interval > 0 ? aws_iam_role.monitoring[0].arn : null
  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_enabled ? 7 : null
  enabled_cloudwatch_logs_exports       = ["postgresql", "upgrade"]

  # Lifecycle
  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : var.final_snapshot_identifier
  apply_immediately         = var.apply_immediately

  tags = merge(var.tags, {
    Name = "${var.name}-db"
  })
}
