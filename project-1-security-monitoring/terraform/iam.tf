# =============================================================================
# IAM Roles and Policies - Phase 2 Log Ingestion
# =============================================================================
# Creates IAM roles for:
# 1. EC2 instance to run CloudWatch Agent and publish logs
# 2. VPC Flow Logs service to write to CloudWatch Logs
#
# All policies follow least privilege - only permissions required for logging.
# =============================================================================

# =============================================================================
# SECTION 1: EC2 CloudWatch Agent IAM Resources
# =============================================================================

# -----------------------------------------------------------------------------
# IAM Role: EC2 CloudWatch Agent
# -----------------------------------------------------------------------------
# Allows EC2 instances to assume this role for CloudWatch Agent operations.
# -----------------------------------------------------------------------------
resource "aws_iam_role" "ec2_cloudwatch_agent" {
  name        = "${var.project_name}-${var.environment}-ec2-cw-agent-role"
  description = "IAM role for EC2 instance to run CloudWatch Agent"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EC2AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-ec2-cw-agent-role"
  }
}

# -----------------------------------------------------------------------------
# IAM Policy: CloudWatch Agent Permissions
# -----------------------------------------------------------------------------
# Grants minimum permissions required for CloudWatch Agent to:
# - Create log streams within existing log groups
# - Write log events to CloudWatch Logs
# - Describe log groups and streams (required for agent startup)
#
# Resource constraints limit access to only the project's log groups.
# -----------------------------------------------------------------------------
resource "aws_iam_policy" "cloudwatch_agent" {
  name        = "${var.project_name}-${var.environment}-cw-agent-policy"
  description = "Policy allowing CloudWatch Agent to write logs to specific log groups"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CloudWatchLogsCreateAndPut"
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = [
          "${aws_cloudwatch_log_group.ec2_system.arn}:*",
          "${aws_cloudwatch_log_group.ec2_secure.arn}:*"
        ]
      },
      {
        Sid    = "CloudWatchLogsDescribeGroups"
        Effect = "Allow"
        Action = [
          "logs:DescribeLogGroups"
        ]
        Resource = "arn:aws:logs:*:*:log-group:*"
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-cw-agent-policy"
  }
}

# -----------------------------------------------------------------------------
# IAM Role Policy Attachment: CloudWatch Agent
# -----------------------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.ec2_cloudwatch_agent.name
  policy_arn = aws_iam_policy.cloudwatch_agent.arn
}

# -----------------------------------------------------------------------------
# IAM Instance Profile: EC2 CloudWatch Agent
# -----------------------------------------------------------------------------
# Instance profile that allows EC2 to assume the CloudWatch Agent role.
# This is attached to the EC2 instance.
# -----------------------------------------------------------------------------
resource "aws_iam_instance_profile" "ec2_cloudwatch_agent" {
  name = "${var.project_name}-${var.environment}-ec2-cw-agent-profile"
  role = aws_iam_role.ec2_cloudwatch_agent.name

  tags = {
    Name = "${var.project_name}-${var.environment}-ec2-cw-agent-profile"
  }
}

# =============================================================================
# SECTION 2: VPC Flow Logs IAM Resources
# =============================================================================

# -----------------------------------------------------------------------------
# IAM Role: VPC Flow Logs
# -----------------------------------------------------------------------------
# Allows VPC Flow Logs service to assume this role for writing logs.
# -----------------------------------------------------------------------------
resource "aws_iam_role" "vpc_flow_logs" {
  name        = "${var.project_name}-${var.environment}-vpc-flow-logs-role"
  description = "IAM role for VPC Flow Logs to write to CloudWatch Logs"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "VPCFlowLogsAssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-vpc-flow-logs-role"
  }
}

# -----------------------------------------------------------------------------
# IAM Policy: VPC Flow Logs Permissions
# -----------------------------------------------------------------------------
# Grants minimum permissions for VPC Flow Logs service to:
# - Create log streams
# - Write log events
# - Describe log groups and streams
#
# Resource constraint limits access to only the VPC flow logs log group.
# -----------------------------------------------------------------------------
resource "aws_iam_policy" "vpc_flow_logs" {
  name        = "${var.project_name}-${var.environment}-vpc-flow-logs-policy"
  description = "Policy allowing VPC Flow Logs to write to CloudWatch Logs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "VPCFlowLogsWrite"
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams",
          "logs:DescribeLogGroups"
        ]
        Resource = [
          aws_cloudwatch_log_group.vpc_flow_logs.arn,
          "${aws_cloudwatch_log_group.vpc_flow_logs.arn}:*"
        ]
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-vpc-flow-logs-policy"
  }
}

# -----------------------------------------------------------------------------
# IAM Role Policy Attachment: VPC Flow Logs
# -----------------------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "vpc_flow_logs" {
  role       = aws_iam_role.vpc_flow_logs.name
  policy_arn = aws_iam_policy.vpc_flow_logs.arn
}

# =============================================================================
# SECTION 3: Lambda Alert Enrichment IAM Resources (Phase 4)
# =============================================================================

# -----------------------------------------------------------------------------
# IAM Role: Lambda Alert Enrichment
# -----------------------------------------------------------------------------
# Allows Lambda service to assume this role for alert enrichment operations.
# -----------------------------------------------------------------------------
resource "aws_iam_role" "lambda_alert_enrichment" {
  name        = "${var.project_name}-${var.environment}-lambda-enrichment-role"
  description = "IAM role for Lambda function to enrich security alerts"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "LambdaAssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-lambda-enrichment-role"
  }
}

# -----------------------------------------------------------------------------
# IAM Policy: Lambda Alert Enrichment Permissions
# -----------------------------------------------------------------------------
# Grants minimum permissions required for Lambda to:
# - Write execution logs to CloudWatch Logs
# - Create log streams and log groups (standard Lambda permissions)
#
# NOTE: No permissions for modifying infrastructure or blocking actions.
# Lambda is read-only for enrichment purposes only.
# -----------------------------------------------------------------------------
resource "aws_iam_policy" "lambda_alert_enrichment" {
  name        = "${var.project_name}-${var.environment}-lambda-enrichment-policy"
  description = "Policy allowing Lambda to write logs for alert enrichment"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CloudWatchLogsWrite"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:log-group:/aws/lambda/${var.project_name}-${var.environment}-alert-enrichment:*"
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-lambda-enrichment-policy"
  }
}

# -----------------------------------------------------------------------------
# IAM Role Policy Attachment: Lambda Alert Enrichment
# -----------------------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "lambda_alert_enrichment" {
  role       = aws_iam_role.lambda_alert_enrichment.name
  policy_arn = aws_iam_policy.lambda_alert_enrichment.arn
}
