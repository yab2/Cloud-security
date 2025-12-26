# =============================================================================
# Lambda Function - Phase 4 Alert Enrichment
# =============================================================================
# Creates Lambda function for enriching security alerts with:
# - IP address extraction
# - Geolocation lookup
# - Severity classification
# - Recommended response actions
#
# The function is triggered by SNS notifications from CloudWatch Alarms.
# =============================================================================

# -----------------------------------------------------------------------------
# Data: Archive Lambda Function Code
# -----------------------------------------------------------------------------
# Creates a ZIP archive of the Lambda function code for deployment.
# -----------------------------------------------------------------------------
data "archive_file" "lambda_alert_enrichment" {
  type        = "zip"
  source_file = "${path.module}/../lambda/alert_enrichment.py"
  output_path = "${path.module}/.terraform/lambda_alert_enrichment.zip"
}

# -----------------------------------------------------------------------------
# Lambda Function: Alert Enrichment
# -----------------------------------------------------------------------------
resource "aws_lambda_function" "alert_enrichment" {
  function_name    = "${var.project_name}-${var.environment}-alert-enrichment"
  description      = "Enriches security alerts with geolocation and contextual information"
  role             = aws_iam_role.lambda_alert_enrichment.arn
  handler          = "alert_enrichment.lambda_handler"
  runtime          = "python3.11"
  timeout          = 30
  memory_size      = 256
  source_code_hash = data.archive_file.lambda_alert_enrichment.output_base64sha256
  filename         = data.archive_file.lambda_alert_enrichment.output_path

  environment {
    variables = {
      PROJECT_NAME = var.project_name
      ENVIRONMENT  = var.environment
      LOG_LEVEL    = "INFO"
    }
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-alert-enrichment"
    Description = "Security alert enrichment Lambda function"
  }
}

# -----------------------------------------------------------------------------
# CloudWatch Log Group: Lambda Function Logs
# -----------------------------------------------------------------------------
# Explicitly create log group with retention policy for Lambda execution logs.
# -----------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "lambda_alert_enrichment" {
  name              = "/aws/lambda/${aws_lambda_function.alert_enrichment.function_name}"
  retention_in_days = 30

  tags = {
    Name        = "${var.project_name}-${var.environment}-lambda-logs"
    Description = "Lambda alert enrichment execution logs"
  }
}

# -----------------------------------------------------------------------------
# Lambda Permission: Allow SNS to Invoke
# -----------------------------------------------------------------------------
# Grants SNS topic permission to invoke the Lambda function.
# -----------------------------------------------------------------------------
resource "aws_lambda_permission" "allow_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.alert_enrichment.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.security_alerts.arn
}

# -----------------------------------------------------------------------------
# SNS Topic Subscription: Lambda
# -----------------------------------------------------------------------------
# Subscribes Lambda function to SNS topic to receive alert notifications.
# This subscription is automatically confirmed (no manual action required).
# -----------------------------------------------------------------------------
resource "aws_sns_topic_subscription" "lambda_alerts" {
  topic_arn = aws_sns_topic.security_alerts.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.alert_enrichment.arn
}
