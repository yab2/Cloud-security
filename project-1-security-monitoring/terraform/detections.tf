# =============================================================================
# CloudWatch Metric Filters and Alarms - Phase 3 Security Detections
# =============================================================================
# Implements security detections using CloudWatch Metric Filters and Alarms.
# Uses ONLY existing Log Groups from Phase 2.
#
# Detections implemented:
# 1. Failed SSH Login Attempts (SSH Brute Force)
# 2. Root Login Attempts
# 3. Invalid SSH Users
# 4. Port Scanning via VPC Flow Logs
#
# NOTE: No SNS topics, Lambda functions, or dashboards are created in Phase 3.
# Alarms are created without notification actions (actions added in Phase 4).
# =============================================================================

# =============================================================================
# DETECTION 1: Failed SSH Login Attempts (SSH Brute Force)
# =============================================================================
# Source: /var/log/secure (ec2_secure log group)
# Pattern: "Failed password" entries indicate failed authentication attempts
# Threshold: > 5 failures in 5 minutes (as per README)
# =============================================================================

resource "aws_cloudwatch_log_metric_filter" "failed_ssh_login" {
  name           = "${var.project_name}-${var.environment}-failed-ssh-login"
  log_group_name = aws_cloudwatch_log_group.ec2_secure.name
  pattern        = "\"Failed password\""

  metric_transformation {
    name          = "FailedSSHLoginAttempts"
    namespace     = "${var.project_name}/${var.environment}/Security"
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_metric_alarm" "failed_ssh_login" {
  alarm_name          = "${var.project_name}-${var.environment}-ssh-brute-force"
  alarm_description   = "Detects potential SSH brute force attacks - more than 5 failed SSH login attempts in 5 minutes"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FailedSSHLoginAttempts"
  namespace           = "${var.project_name}/${var.environment}/Security"
  period              = 300 # 5 minutes
  statistic           = "Sum"
  threshold           = 5
  treat_missing_data  = "notBreaching"

  # Phase 4: Send notifications to SNS topic
  alarm_actions = [aws_sns_topic.security_alerts.arn]

  tags = {
    Name          = "${var.project_name}-${var.environment}-ssh-brute-force-alarm"
    DetectionType = "ssh-brute-force"
    Severity      = "high"
    Description   = "Triggers when > 5 failed SSH logins occur in 5 minutes"
  }
}

# =============================================================================
# DETECTION 2: Root Login Attempts
# =============================================================================
# Source: /var/log/secure (ec2_secure log group)
# Pattern: "Failed password for root" indicates attempted root authentication
# Threshold: Any occurrence (> 0) - as per README
# =============================================================================

resource "aws_cloudwatch_log_metric_filter" "root_login_attempt" {
  name           = "${var.project_name}-${var.environment}-root-login-attempt"
  log_group_name = aws_cloudwatch_log_group.ec2_secure.name
  pattern        = "\"Failed password for root\""

  metric_transformation {
    name          = "RootLoginAttempts"
    namespace     = "${var.project_name}/${var.environment}/Security"
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_metric_alarm" "root_login_attempt" {
  alarm_name          = "${var.project_name}-${var.environment}-root-login-attempt"
  alarm_description   = "Detects any attempt to login as root via SSH - any occurrence triggers immediate alert"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "RootLoginAttempts"
  namespace           = "${var.project_name}/${var.environment}/Security"
  period              = 60 # 1 minute - immediate detection
  statistic           = "Sum"
  threshold           = 0 # Any occurrence triggers alarm
  treat_missing_data  = "notBreaching"

  # Phase 4: Send notifications to SNS topic
  alarm_actions = [aws_sns_topic.security_alerts.arn]

  tags = {
    Name          = "${var.project_name}-${var.environment}-root-login-alarm"
    DetectionType = "root-login-attempt"
    Severity      = "critical"
    Description   = "Triggers on any root login attempt"
  }
}

# =============================================================================
# DETECTION 3: Invalid SSH Users
# =============================================================================
# Source: /var/log/secure (ec2_secure log group)
# Pattern: "Invalid user" indicates login attempt with non-existent username
# Threshold: > 3 in 5 minutes (as per README)
# =============================================================================

resource "aws_cloudwatch_log_metric_filter" "invalid_ssh_user" {
  name           = "${var.project_name}-${var.environment}-invalid-ssh-user"
  log_group_name = aws_cloudwatch_log_group.ec2_secure.name
  pattern        = "\"Invalid user\""

  metric_transformation {
    name          = "InvalidSSHUserAttempts"
    namespace     = "${var.project_name}/${var.environment}/Security"
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_metric_alarm" "invalid_ssh_user" {
  alarm_name          = "${var.project_name}-${var.environment}-invalid-user-enumeration"
  alarm_description   = "Detects user enumeration attempts - login attempts for non-existent users indicate reconnaissance"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "InvalidSSHUserAttempts"
  namespace           = "${var.project_name}/${var.environment}/Security"
  period              = 300 # 5 minutes
  statistic           = "Sum"
  threshold           = 3
  treat_missing_data  = "notBreaching"

  # Phase 4: Send notifications to SNS topic
  alarm_actions = [aws_sns_topic.security_alerts.arn]

  tags = {
    Name          = "${var.project_name}-${var.environment}-invalid-user-alarm"
    DetectionType = "user-enumeration"
    Severity      = "medium"
    Description   = "Triggers when > 3 invalid user attempts occur in 5 minutes"
  }
}

# =============================================================================
# DETECTION 4: Port Scanning via VPC Flow Logs
# =============================================================================
# Source: VPC Flow Logs (vpc_flow_logs log group)
# Pattern: REJECT actions on port 22 indicate connection attempts blocked by SG
# Threshold: > 20 rejected connections in 1 minute (as per README)
#
# VPC Flow Log Default Format (space-separated):
# version account-id interface-id srcaddr dstaddr srcport dstport protocol packets bytes start end action log-status
#
# We filter for: action=REJECT (blocked by security group/NACL)
# High volume of REJECT indicates scanning activity
# =============================================================================

resource "aws_cloudwatch_log_metric_filter" "port_scan" {
  name           = "${var.project_name}-${var.environment}-port-scan"
  log_group_name = aws_cloudwatch_log_group.vpc_flow_logs.name

  # VPC Flow Log filter pattern (space-separated positional fields)
  # [version, account, eni, source, destination, srcport, destport, protocol, packets, bytes, windowstart, windowend, action="REJECT", flowlogstatus]
  pattern = "[version, account, eni, source, destination, srcport, destport, protocol, packets, bytes, windowstart, windowend, action=\"REJECT\", flowlogstatus]"

  metric_transformation {
    name          = "RejectedConnections"
    namespace     = "${var.project_name}/${var.environment}/Security"
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_metric_alarm" "port_scan" {
  alarm_name          = "${var.project_name}-${var.environment}-port-scan-detected"
  alarm_description   = "Detects potential port scanning - high volume of rejected connections indicates reconnaissance"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "RejectedConnections"
  namespace           = "${var.project_name}/${var.environment}/Security"
  period              = 60 # 1 minute
  statistic           = "Sum"
  threshold           = 20
  treat_missing_data  = "notBreaching"

  # Phase 4: Send notifications to SNS topic
  alarm_actions = [aws_sns_topic.security_alerts.arn]

  tags = {
    Name          = "${var.project_name}-${var.environment}-port-scan-alarm"
    DetectionType = "port-scan"
    Severity      = "high"
    Description   = "Triggers when > 20 rejected connections occur in 1 minute"
  }
}
