# =============================================================================
# CloudWatch Log Groups - Phase 2 Log Ingestion
# =============================================================================
# Creates CloudWatch Log Groups for centralized log collection from:
# - EC2 instance system/authentication logs (via CloudWatch Agent)
# - VPC Flow Logs (network traffic metadata)
#
# NOTE: No metric filters, alarms, or dashboards are created in Phase 2.
# =============================================================================

# -----------------------------------------------------------------------------
# Log Group: EC2 System Logs
# -----------------------------------------------------------------------------
# Collects /var/log/messages from the EC2 instance via CloudWatch Agent.
# Contains general system events, service status, and application logs.
# -----------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "ec2_system" {
  name              = "/${var.project_name}/${var.environment}/ec2/system"
  retention_in_days = 30

  tags = {
    Name        = "${var.project_name}-${var.environment}-ec2-system-logs"
    LogType     = "ec2-system"
    Description = "EC2 system logs from /var/log/messages"
  }
}

# -----------------------------------------------------------------------------
# Log Group: EC2 Authentication/Security Logs
# -----------------------------------------------------------------------------
# Collects /var/log/secure from the EC2 instance via CloudWatch Agent.
# Contains SSH login attempts, sudo usage, and authentication events.
# Critical for security monitoring in future phases.
# -----------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "ec2_secure" {
  name              = "/${var.project_name}/${var.environment}/ec2/secure"
  retention_in_days = 30

  tags = {
    Name        = "${var.project_name}-${var.environment}-ec2-secure-logs"
    LogType     = "ec2-auth"
    Description = "EC2 authentication logs from /var/log/secure"
  }
}

# -----------------------------------------------------------------------------
# Log Group: VPC Flow Logs
# -----------------------------------------------------------------------------
# Captures network traffic metadata for the VPC.
# Records accepted/rejected traffic, source/destination IPs, ports, protocols.
# Essential for network security analysis in future phases.
# -----------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/${var.project_name}/${var.environment}/vpc/flow-logs"
  retention_in_days = 30

  tags = {
    Name        = "${var.project_name}-${var.environment}-vpc-flow-logs"
    LogType     = "vpc-flow"
    Description = "VPC Flow Logs for network traffic analysis"
  }
}

# -----------------------------------------------------------------------------
# VPC Flow Logs Resource
# -----------------------------------------------------------------------------
# Enables flow logging at the VPC level, capturing all traffic (ACCEPT/REJECT).
# Logs are sent to the CloudWatch Log Group created above.
# -----------------------------------------------------------------------------
resource "aws_flow_log" "vpc" {
  vpc_id                   = aws_vpc.main.id
  traffic_type             = "ALL"
  log_destination_type     = "cloud-watch-logs"
  log_destination          = aws_cloudwatch_log_group.vpc_flow_logs.arn
  iam_role_arn             = aws_iam_role.vpc_flow_logs.arn
  max_aggregation_interval = 60

  tags = {
    Name = "${var.project_name}-${var.environment}-vpc-flow-log"
  }
}
