data "aws_ami" "app" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = [var.ami_name_pattern]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

check "asg_capacity" {
  assert {
    condition     = var.min_size <= var.desired_capacity && var.desired_capacity <= var.max_size
    error_message = "The ASG capacity must satisfy min_size <= desired_capacity <= max_size."
  }
}

###############################################################################
# IAM: SSM Session Manager + CloudWatch agent, no SSH key required
###############################################################################

data "aws_iam_policy_document" "instance_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "instance" {
  name               = "${var.name}-app-instance"
  description        = "Application EC2 role (SSM managed)"
  assume_role_policy = data.aws_iam_policy_document.instance_assume.json

  tags = merge(var.tags, {
    Name = "${var.name}-app-instance"
  })
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.instance.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "instance" {
  name = "${var.name}-app-instance"
  role = aws_iam_role.instance.name

  tags = var.tags
}

###############################################################################
# Launch template + Auto Scaling group
###############################################################################

resource "aws_launch_template" "app" {
  name_prefix   = "${var.name}-app-"
  image_id      = data.aws_ami.app.id
  instance_type = var.instance_type
  key_name      = var.key_pair_name

  update_default_version = true

  iam_instance_profile {
    arn = aws_iam_instance_profile.instance.arn
  }

  vpc_security_group_ids = [var.app_security_group_id]

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
    instance_metadata_tags      = "disabled"
  }

  monitoring {
    enabled = true
  }

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_type           = "gp3"
      volume_size           = var.root_volume_size
      encrypted             = true
      delete_on_termination = true
    }
  }

  user_data = var.user_data == "" ? null : base64encode(var.user_data)

  tag_specifications {
    resource_type = "instance"

    tags = merge(var.tags, {
      Name = "${var.name}-app"
    })
  }

  tag_specifications {
    resource_type = "volume"

    tags = merge(var.tags, {
      Name = "${var.name}-app"
    })
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = var.tags
}

resource "aws_autoscaling_group" "app" {
  name                = "${var.name}-app-asg"
  vpc_zone_identifier = var.private_subnet_ids

  min_size         = var.min_size
  desired_capacity = var.desired_capacity
  max_size         = var.max_size

  target_group_arns         = var.target_group_arn == null ? [] : [var.target_group_arn]
  health_check_type         = "ELB"
  health_check_grace_period = 300
  default_instance_warmup   = 120

  launch_template {
    id      = aws_launch_template.app.id
    version = aws_launch_template.app.latest_version
  }

  instance_refresh {
    strategy = "Rolling"

    preferences {
      min_healthy_percentage = 50
      instance_warmup        = 120
    }
  }

  dynamic "tag" {
    for_each = merge({ Name = "${var.name}-app" }, var.tags)

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    ignore_changes = [desired_capacity]
  }
}
