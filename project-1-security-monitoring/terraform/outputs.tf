# =============================================================================
# Outputs - Phase 1 Core Infrastructure + Phase 2 Log Ingestion
# =============================================================================
# Exposes essential resource identifiers for validation and future phases.
# =============================================================================

# -----------------------------------------------------------------------------
# Phase 1 Outputs
# -----------------------------------------------------------------------------
output "ec2_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.main.public_ip
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public.id
}

# -----------------------------------------------------------------------------
# Phase 2 Outputs - CloudWatch Log Groups
# -----------------------------------------------------------------------------
output "cloudwatch_log_group_ec2_system" {
  description = "CloudWatch Log Group name for EC2 system logs"
  value       = aws_cloudwatch_log_group.ec2_system.name
}

output "cloudwatch_log_group_ec2_secure" {
  description = "CloudWatch Log Group name for EC2 authentication logs"
  value       = aws_cloudwatch_log_group.ec2_secure.name
}

output "cloudwatch_log_group_vpc_flow_logs" {
  description = "CloudWatch Log Group name for VPC Flow Logs"
  value       = aws_cloudwatch_log_group.vpc_flow_logs.name
}

# -----------------------------------------------------------------------------
# Phase 2 Outputs - IAM Resources
# -----------------------------------------------------------------------------
output "iam_role_ec2_cloudwatch_agent_arn" {
  description = "ARN of the IAM role for EC2 CloudWatch Agent"
  value       = aws_iam_role.ec2_cloudwatch_agent.arn
}

output "iam_role_vpc_flow_logs_arn" {
  description = "ARN of the IAM role for VPC Flow Logs"
  value       = aws_iam_role.vpc_flow_logs.arn
}

# -----------------------------------------------------------------------------
# Phase 2 Outputs - VPC Flow Logs
# -----------------------------------------------------------------------------
output "vpc_flow_log_id" {
  description = "ID of the VPC Flow Log"
  value       = aws_flow_log.vpc.id
}

# -----------------------------------------------------------------------------
# Phase 3 Outputs - Security Detections (Metric Filters and Alarms)
# -----------------------------------------------------------------------------
output "metric_filter_failed_ssh_login" {
  description = "Name of the metric filter for failed SSH login attempts"
  value       = aws_cloudwatch_log_metric_filter.failed_ssh_login.name
}

output "metric_filter_root_login_attempt" {
  description = "Name of the metric filter for root login attempts"
  value       = aws_cloudwatch_log_metric_filter.root_login_attempt.name
}

output "metric_filter_invalid_ssh_user" {
  description = "Name of the metric filter for invalid SSH users"
  value       = aws_cloudwatch_log_metric_filter.invalid_ssh_user.name
}

output "metric_filter_port_scan" {
  description = "Name of the metric filter for port scanning detection"
  value       = aws_cloudwatch_log_metric_filter.port_scan.name
}

output "alarm_ssh_brute_force_arn" {
  description = "ARN of the SSH brute force detection alarm"
  value       = aws_cloudwatch_metric_alarm.failed_ssh_login.arn
}

output "alarm_root_login_arn" {
  description = "ARN of the root login attempt detection alarm"
  value       = aws_cloudwatch_metric_alarm.root_login_attempt.arn
}

output "alarm_invalid_user_arn" {
  description = "ARN of the invalid user enumeration detection alarm"
  value       = aws_cloudwatch_metric_alarm.invalid_ssh_user.arn
}

output "alarm_port_scan_arn" {
  description = "ARN of the port scan detection alarm"
  value       = aws_cloudwatch_metric_alarm.port_scan.arn
}

output "security_metrics_namespace" {
  description = "CloudWatch metrics namespace for security detections"
  value       = "${var.project_name}/${var.environment}/Security"
}

# -----------------------------------------------------------------------------
# Phase 4 Outputs - Alert Delivery and Enrichment
# -----------------------------------------------------------------------------
output "sns_topic_arn" {
  description = "ARN of the SNS topic for security alerts"
  value       = aws_sns_topic.security_alerts.arn
}

output "sns_topic_name" {
  description = "Name of the SNS topic for security alerts"
  value       = aws_sns_topic.security_alerts.name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function for alert enrichment"
  value       = aws_lambda_function.alert_enrichment.arn
}

output "lambda_function_name" {
  description = "Name of the Lambda function for alert enrichment"
  value       = aws_lambda_function.alert_enrichment.function_name
}

output "lambda_iam_role_arn" {
  description = "ARN of the IAM role for Lambda alert enrichment"
  value       = aws_iam_role.lambda_alert_enrichment.arn
}

output "lambda_log_group_name" {
  description = "CloudWatch Log Group name for Lambda execution logs"
  value       = aws_cloudwatch_log_group.lambda_alert_enrichment.name
}

output "alert_email" {
  description = "Email address subscribed to security alerts"
  value       = var.alert_email
  sensitive   = true
}
