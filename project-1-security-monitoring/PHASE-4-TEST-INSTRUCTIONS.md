# Phase 4 - Alert Delivery and Enrichment
## Test Instructions

This document provides step-by-step instructions for deploying and testing Phase 4 of the Cloud Security Monitoring Lab.

---

## Prerequisites

Before starting Phase 4, ensure:
- [x] Phases 1-3 are deployed and working
- [x] You have a valid email address for receiving alerts
- [x] AWS CLI is configured
- [x] You have SSH access to the EC2 instance

---

## Deployment Steps

### Step 1: Add Required Variable

Create or update `terraform/terraform.tfvars` with the alert email:

```hcl
# Existing variables from previous phases
aws_region       = "us-east-1"
project_name     = "security-monitoring"
environment      = "dev"
allowed_ssh_cidr = "YOUR.IP.ADDRESS/32"
instance_type    = "t2.micro"

# NEW: Phase 4 variable
alert_email      = "your-email@example.com"
```

### Step 2: Review Phase 4 Changes

```bash
cd terraform/

# Review what will be created
terraform plan

# You should see:
# - 1 SNS topic
# - 1 SNS topic policy
# - 2 SNS subscriptions (email + lambda)
# - 1 Lambda function
# - 1 Lambda IAM role
# - 1 Lambda IAM policy
# - 1 Lambda CloudWatch log group
# - 1 Lambda permission
# - 4 alarm updates (adding alarm_actions)
```

### Step 3: Deploy Phase 4

```bash
# Apply the changes
terraform apply

# Type 'yes' when prompted
```

### Step 4: Confirm Email Subscription

**IMPORTANT:** Within 5 minutes of deployment, check your email.

1. Look for email from: `no-reply@sns.amazonaws.com`
2. Subject: `AWS Notification - Subscription Confirmation`
3. Click the **"Confirm subscription"** link
4. You should see a confirmation page in your browser

> If you don't receive the email:
> - Check spam/junk folder
> - Verify email address in terraform.tfvars
> - Run: `aws sns list-subscriptions` to verify subscription is pending

### Step 5: Verify Deployment

```bash
# Get outputs
terraform output

# Verify SNS topic
aws sns list-topics | grep security-alerts

# Verify Lambda function
aws lambda list-functions | grep alert-enrichment

# Verify email subscription status (should show "Confirmed")
aws sns list-subscriptions-by-topic \
  --topic-arn $(terraform output -raw sns_topic_arn)
```

---

## Testing Alert Delivery

### Test 1: Trigger SSH Brute Force Alert

This test will generate failed SSH login attempts to trigger the brute force detection.

```bash
# Get EC2 public IP
EC2_IP=$(cd terraform && terraform output -raw ec2_public_ip)

# Trigger 10 failed SSH attempts
for i in {1..10}; do
  echo "Attempt $i of 10..."
  ssh -o StrictHostKeyChecking=no \
      -o ConnectTimeout=5 \
      -o PreferredAuthentications=password \
      fakeuser@$EC2_IP 2>/dev/null || true
  sleep 1
done

echo "Test complete. Wait 2-3 minutes for alarm to trigger..."
```

**Expected Results:**
1. CloudWatch alarm enters "ALARM" state (2-3 minutes)
2. Email alert arrives with alarm details (3-5 minutes)
3. Lambda function is invoked (check logs)

### Test 2: Verify Email Alert

Check your email inbox for:

- **From:** AWS Notifications
- **Subject:** ALARM: `<project>-<env>-ssh-brute-force`
- **Body:** Contains alarm details and threshold information

### Test 3: Verify Lambda Enrichment

```bash
# View Lambda logs in real-time
aws logs tail /aws/lambda/security-monitoring-dev-alert-enrichment --follow

# Or view recent logs
aws logs tail /aws/lambda/security-monitoring-dev-alert-enrichment --since 10m
```

**Look for:**
- `[INFO] Alert enrichment function triggered`
- `[INFO] Processing alarm: <alarm-name>`
- `[ALERT]` JSON with enriched data including:
  - `detection_type`: "SSH Brute Force Attack"
  - `severity`: "HIGH"
  - `source_ips`: Array of IPs (if detected)
  - `geolocation`: Country, city, ISP info
  - `recommendations`: List of response actions

### Test 4: Check CloudWatch Console

1. Navigate to CloudWatch in AWS Console
2. Go to **Alarms** → **All alarms**
3. Find `<project>-<env>-ssh-brute-force`
4. Verify state is "In alarm" (red)
5. Click the alarm → View **History** tab
6. You should see state change from OK → ALARM

### Test 5: Verify All 4 Alarms Have Notifications

```bash
# Check that all alarms have alarm_actions configured
aws cloudwatch describe-alarms \
  --alarm-name-prefix "security-monitoring-dev" \
  --query 'MetricAlarms[*].[AlarmName,ActionsEnabled,length(AlarmActions)]' \
  --output table
```

**Expected Output:**
```
|---------------------------------------------------------------------|
|  security-monitoring-dev-ssh-brute-force      | True  | 1         |
|  security-monitoring-dev-root-login-attempt   | True  | 1         |
|  security-monitoring-dev-invalid-user-enum... | True  | 1         |
|  security-monitoring-dev-port-scan-detected   | True  | 1         |
|---------------------------------------------------------------------|
```

---

## Testing Other Detections

### Test Root Login Attempt

```bash
# Single root login attempt
ssh -o StrictHostKeyChecking=no \
    -o ConnectTimeout=5 \
    -o PreferredAuthentications=password \
    root@$EC2_IP

# Enter any password (will fail)
# Wait 1-2 minutes for alarm
```

### Test Invalid User Enumeration

```bash
# Try multiple non-existent users
for user in admin administrator test guest operator; do
  echo "Testing user: $user"
  ssh -o StrictHostKeyChecking=no \
      -o ConnectTimeout=5 \
      -o PreferredAuthentications=password \
      ${user}@$EC2_IP 2>/dev/null || true
  sleep 1
done
```

### Test Port Scan Detection

```bash
# WARNING: Only run from your authorized IP
# Requires nmap installed: sudo apt install nmap

nmap -Pn -p 1-100 $EC2_IP
# Most ports will be REJECTED by Security Group
# Wait 1-2 minutes for alarm
```

---

## Troubleshooting

### Issue: Email Not Received

**Check 1:** Verify subscription status
```bash
aws sns list-subscriptions-by-topic \
  --topic-arn $(cd terraform && terraform output -raw sns_topic_arn) \
  --query 'Subscriptions[?Protocol==`email`]'
```

**Solution:**
- If status is "PendingConfirmation", check spam folder
- If email is wrong, update terraform.tfvars and run `terraform apply`

### Issue: Lambda Not Invoked

**Check 1:** Verify Lambda permission
```bash
aws lambda get-policy \
  --function-name security-monitoring-dev-alert-enrichment \
  --query 'Policy' \
  --output text | jq
```

**Check 2:** Verify SNS subscription
```bash
aws sns list-subscriptions-by-topic \
  --topic-arn $(cd terraform && terraform output -raw sns_topic_arn) \
  --query 'Subscriptions[?Protocol==`lambda`]'
```

**Solution:**
- Run `terraform apply` again to recreate resources
- Check Lambda function exists: `aws lambda get-function --function-name <name>`

### Issue: Alarm Not Triggering

**Check 1:** Verify metric filter is working
```bash
aws logs describe-metric-filters \
  --log-group-name "/security-monitoring/dev/ec2/secure"
```

**Check 2:** Check if logs are reaching CloudWatch
```bash
aws logs tail /security-monitoring/dev/ec2/secure --since 10m
```

**Solution:**
- Verify Phase 3 is working (metric filters exist)
- Check EC2 CloudWatch Agent is running (SSH to instance)
- Wait 5-10 minutes for logs to appear

### Issue: Geolocation Not Working

**Check Lambda logs:**
```bash
aws logs tail /aws/lambda/security-monitoring-dev-alert-enrichment --since 30m
```

**Look for:**
- `[WARN] Geolocation lookup failed` - API rate limit or network issue
- `error: Geolocation service unavailable` - Temporary API issue

**Note:** Private IPs (10.x.x.x, 192.168.x.x) will show "Internal/Private" - this is expected.

---

## Manual Lambda Test

Test Lambda function directly without triggering an alarm:

### Step 1: Create Test Event

Create `test_event.json`:

```json
{
  "Records": [
    {
      "EventSource": "aws:sns",
      "Sns": {
        "Message": "{\"AlarmName\":\"security-monitoring-dev-ssh-brute-force\",\"AlarmDescription\":\"Detects potential SSH brute force attacks\",\"NewStateValue\":\"ALARM\",\"NewStateReason\":\"Threshold Crossed: 6 failed SSH attempts detected from 203.0.113.50\",\"StateChangeTime\":\"2025-12-16T12:00:00.000Z\"}"
      }
    }
  ]
}
```

### Step 2: Invoke Lambda

```bash
aws lambda invoke \
  --function-name security-monitoring-dev-alert-enrichment \
  --payload file://test_event.json \
  response.json

# View response
cat response.json | jq

# Check logs
aws logs tail /aws/lambda/security-monitoring-dev-alert-enrichment --since 1m
```

---

## Clean Up (Optional)

To remove Phase 4 resources but keep Phases 1-3:

```bash
# Remove Lambda and SNS resources manually
# Or comment out in Terraform and run:
terraform apply
```

To remove everything:

```bash
cd terraform/
terraform destroy
```

---

## Next Steps

After successful Phase 4 testing:

1. Review enriched alert logs for actionable insights
2. Consider implementing automated response (Phase 5)
3. Add CloudWatch Dashboard for visualization
4. Integrate with incident response workflow
5. Document runbook for security team

---

## Phase 4 Success Checklist

- [ ] SNS topic created
- [ ] Email subscription confirmed
- [ ] Lambda function deployed
- [ ] All 4 alarms have SNS actions configured
- [ ] Test alert successfully triggered
- [ ] Email alert received
- [ ] Lambda enrichment logs show geolocation data
- [ ] No errors in Lambda logs
- [ ] Alarm returns to OK state after test

**Congratulations!** Phase 4 is complete when all checkboxes are marked.
