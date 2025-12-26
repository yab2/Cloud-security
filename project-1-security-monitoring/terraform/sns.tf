# =============================================================================
# SNS Topic and Subscriptions - Phase 4 Alert Delivery
# =============================================================================
# Creates SNS topic for security alert notifications.
# Email subscription requires manual confirmation by the subscriber.
#
# The SNS topic serves as the central notification hub for CloudWatch Alarms.
# Lambda function will also subscribe to this topic for alert enrichment.
# =============================================================================

# -----------------------------------------------------------------------------
# SNS Topic: Security Alerts
# -----------------------------------------------------------------------------
resource "aws_sns_topic" "security_alerts" {
  name         = "${var.project_name}-${var.environment}-security-alerts"
  display_name = "Security Monitoring Alerts"

  tags = {
    Name        = "${var.project_name}-${var.environment}-security-alerts"
    Description = "Central topic for all security-related alerts"
  }
}

# -----------------------------------------------------------------------------
# SNS Topic Policy: Allow CloudWatch Alarms to Publish
# -----------------------------------------------------------------------------
resource "aws_sns_topic_policy" "security_alerts" {
  arn = aws_sns_topic.security_alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudWatchAlarmsToPublish"
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action = [
          "SNS:Publish"
        ]
        Resource = aws_sns_topic.security_alerts.arn
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# SNS Email Subscription
# -----------------------------------------------------------------------------
# NOTE: This subscription requires manual confirmation via email.
# After terraform apply, the subscriber will receive a confirmation email
# and must click the "Confirm subscription" link to activate alerts.
# -----------------------------------------------------------------------------
resource "aws_sns_topic_subscription" "email_alerts" {
  topic_arn = aws_sns_topic.security_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email

  # Email subscriptions cannot be auto-confirmed via Terraform
  # User must manually confirm via the email link sent by AWS
}
