output "asg_name" {
  description = "Name of the application Auto Scaling group"
  value       = aws_autoscaling_group.app.name
}

output "asg_arn" {
  description = "ARN of the application Auto Scaling group"
  value       = aws_autoscaling_group.app.arn
}

output "ami_id" {
  description = "AMI resolved for the application instances"
  value       = data.aws_ami.app.id
}

output "instance_role_arn" {
  description = "IAM role ARN attached to the instances"
  value       = aws_iam_role.instance.arn
}

output "launch_template_id" {
  description = "ID of the launch template"
  value       = aws_launch_template.app.id
}
