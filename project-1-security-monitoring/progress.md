# Project 1: Cloud Security Monitoring Lab - Progress Tracker

## Phase 1 - Core Infrastructure Skeleton
**Status:** Completed
**Date:** 2025-12-16

### Phase Goal
Provision a minimal AWS foundation that supports future SOC capabilities.

### Completed Tasks
- [x] Created terraform/ directory structure
- [x] Created main.tf with Terraform and AWS provider configuration
- [x] Created variables.tf with all 5 required variables (aws_region, project_name, environment, allowed_ssh_cidr, instance_type)
- [x] Created vpc.tf with VPC (10.0.0.0/16), Public Subnet (10.0.1.0/24), Internet Gateway, Route Table, and Route Table Association
- [x] Created ec2.tf with Amazon Linux 2 AMI data source, Security Group (SSH restricted), and EC2 instance
- [x] Created outputs.tf with all 3 required outputs (ec2_public_ip, vpc_id, subnet_id)

### File Structure Delivered
```
terraform/
├── main.tf        (Provider configuration, Terraform version constraint)
├── variables.tf   (5 variables with types and descriptions)
├── vpc.tf         (VPC, Subnet, IGW, Route Table, RT Association)
├── ec2.tf         (AMI data source, Security Group, EC2 Instance)
└── outputs.tf     (3 outputs)
```

### Validation Results
- Terraform version constraint: >= 1.0 (VERIFIED)
- Amazon Linux 2 AMI: Retrieved via data source with filters, no hardcoded AMI ID (VERIFIED)
- Instance type: Default t2.micro (VERIFIED)
- SSH restriction: Port 22 only from allowed_ssh_cidr variable (VERIFIED)
- Tagging: All resources tagged with project_name and environment via default_tags + Name tags (VERIFIED)
- All 5 required variables defined with correct types (VERIFIED)
- All 3 required outputs defined (VERIFIED)
- Resource references: All cross-references between resources validated (VERIFIED)

### Known Issues/Risks
- No SSH key pair configured on EC2 instance (not required in Phase 1 scope)
- Availability zone hardcoded to region + "a" suffix (e.g., us-east-1a) - may need adjustment if AZ "a" unavailable in selected region
- No terraform.tfvars file created (user must create and populate before running terraform apply)

### Explicitly NOT Complete (Forbidden in Phase 1)
- CloudWatch Logs or Log Groups
- CloudWatch Metric Filters
- CloudWatch Alarms
- CloudWatch Dashboard
- IAM roles or policies (beyond basic EC2 defaults)
- Lambda functions
- SNS topics or subscriptions
- S3 buckets for log storage
- VPC Flow Logs
- Security detections or alerting
- Alert enrichment

### Next Phase Prerequisites
Before proceeding to Phase 2, the user must:
1. Create a terraform.tfvars file with values for: aws_region, project_name, environment, allowed_ssh_cidr
2. Run `terraform init` to initialize the working directory
3. Run `terraform plan` to validate configuration
4. Run `terraform apply` to deploy infrastructure
5. Verify EC2 instance is accessible and running

---

## Phase 2 - Centralized Log Ingestion
**Status:** Completed
**Date:** 2025-12-16

### Phase Goal
Enable centralized log ingestion into CloudWatch Logs from EC2 and VPC.

### Completed Tasks
- [x] Created CloudWatch Log Group for EC2 system logs (`/{project_name}/{environment}/ec2/system`)
- [x] Created CloudWatch Log Group for EC2 authentication logs (`/{project_name}/{environment}/ec2/secure`)
- [x] Created CloudWatch Log Group for VPC Flow Logs (`/{project_name}/{environment}/vpc/flow-logs`)
- [x] Created IAM role for EC2 CloudWatch Agent with least privilege policy
- [x] Created IAM instance profile for EC2 to assume CloudWatch Agent role
- [x] Created IAM role for VPC Flow Logs with least privilege policy
- [x] Created CloudWatch Agent configuration template (JSON)
- [x] Configured EC2 user_data to install and start CloudWatch Agent
- [x] Enabled VPC Flow Logs at VPC level with CloudWatch destination
- [x] Added Phase 2 outputs for all new resources

### File Structure Delivered
```
terraform/
├── main.tf                (Unchanged - Provider configuration)
├── variables.tf           (Unchanged - 5 variables)
├── vpc.tf                 (Unchanged - VPC, Subnet, IGW, Route Table)
├── ec2.tf                 (UPDATED - Added IAM instance profile + user_data)
├── outputs.tf             (UPDATED - Added 6 new Phase 2 outputs)
├── cloudwatch.tf          (NEW - Log Groups + VPC Flow Log resource)
├── iam.tf                 (NEW - IAM roles and policies)
└── files/
    └── cloudwatch_agent_config.json.tpl  (NEW - Agent configuration template)
```

### New Resources Created
| Resource Type | Name Pattern | Purpose |
|---------------|--------------|---------|
| aws_cloudwatch_log_group | ec2_system | Collects /var/log/messages |
| aws_cloudwatch_log_group | ec2_secure | Collects /var/log/secure |
| aws_cloudwatch_log_group | vpc_flow_logs | VPC network traffic metadata |
| aws_iam_role | ec2_cloudwatch_agent | EC2 assumes for agent |
| aws_iam_policy | cloudwatch_agent | Allows log writes to EC2 log groups |
| aws_iam_instance_profile | ec2_cloudwatch_agent | Attached to EC2 instance |
| aws_iam_role | vpc_flow_logs | VPC Flow Logs service assumes |
| aws_iam_policy | vpc_flow_logs | Allows writes to VPC flow log group |
| aws_flow_log | vpc | Captures all VPC traffic |

### IAM Policy Summary (Least Privilege)
**EC2 CloudWatch Agent Policy:**
- `logs:CreateLogStream` - Only on EC2 system and secure log groups
- `logs:PutLogEvents` - Only on EC2 system and secure log groups
- `logs:DescribeLogStreams` - Only on EC2 system and secure log groups
- `logs:DescribeLogGroups` - Required for agent startup (broader scope necessary)

**VPC Flow Logs Policy:**
- `logs:CreateLogStream` - Only on VPC flow logs log group
- `logs:PutLogEvents` - Only on VPC flow logs log group
- `logs:DescribeLogStreams` - Only on VPC flow logs log group
- `logs:DescribeLogGroups` - Only on VPC flow logs log group

### Validation Steps
After running `terraform apply`, verify log ingestion with these steps:

**1. Verify CloudWatch Log Groups exist:**
```bash
aws logs describe-log-groups --log-group-name-prefix "/<project_name>/<environment>" --region <region>
```
Expected: Three log groups listed (ec2/system, ec2/secure, vpc/flow-logs)

**2. Verify VPC Flow Logs are enabled:**
```bash
aws ec2 describe-flow-logs --filter "Name=resource-id,Values=<vpc_id>" --region <region>
```
Expected: Flow log with status "ACTIVE" and log-destination-type "cloud-watch-logs"

**3. Verify EC2 instance has IAM role attached:**
```bash
aws ec2 describe-instances --instance-ids <instance_id> --query "Reservations[].Instances[].IamInstanceProfile" --region <region>
```
Expected: IAM instance profile ARN containing "ec2-cw-agent-profile"

**4. Verify CloudWatch Agent is running (SSH into EC2):**
```bash
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -m ec2 -a status
```
Expected: Status "running" with configuration file loaded

**5. Verify logs are appearing in CloudWatch (wait 5-10 minutes after deploy):**
```bash
# Check EC2 secure logs
aws logs describe-log-streams --log-group-name "/<project_name>/<environment>/ec2/secure" --region <region>

# Check EC2 system logs
aws logs describe-log-streams --log-group-name "/<project_name>/<environment>/ec2/system" --region <region>

# Check VPC Flow Logs
aws logs describe-log-streams --log-group-name "/<project_name>/<environment>/vpc/flow-logs" --region <region>
```
Expected: Log streams created with recent timestamps

**6. Generate test authentication event (optional):**
```bash
# SSH into EC2 and run sudo command to generate secure log entry
sudo whoami
# Wait 1-2 minutes, then check CloudWatch for new log events
```

### Known Issues/Risks
- EC2 instance will be replaced on first apply after Phase 2 due to user_data addition (user_data_replace_on_change = true)
- CloudWatch Agent logs may take 5-10 minutes to appear after instance starts
- No SSH key pair configured (inherited from Phase 1) - instance access requires separate key setup
- Log retention set to 30 days - adjust in cloudwatch.tf if different retention needed
- VPC Flow Logs aggregation interval set to 60 seconds (minimum for CloudWatch destination)

### Explicitly NOT Complete (Forbidden until Phase 3+)
- CloudWatch Metric Filters (not created - Phase 3 scope)
- CloudWatch Alarms (not created - Phase 3 scope)
- CloudWatch Dashboard (not created - Phase 4+ scope)
- SNS topics or subscriptions (not created - Phase 3+ scope)
- Lambda functions (not created - future phases)
- S3 buckets for log storage (not created - not in current scope)
- Security detections or alerting (not created - Phase 3 scope)
- Alert enrichment (not created - future phases)

### Dependencies for Next Phase
Before proceeding to Phase 3, the user should:
1. Run `terraform plan` to validate Phase 2 changes
2. Run `terraform apply` to deploy Phase 2 infrastructure
3. Wait 10-15 minutes for EC2 instance to initialize and start logging
4. Verify logs are appearing in all three CloudWatch Log Groups
5. Confirm VPC Flow Logs are generating network metadata

---

## Phase 3 - Security Detections
**Status:** Completed
**Date:** 2025-12-16

### Phase Goal
Implement security detections using CloudWatch Metric Filters and Alarms to detect security threats in real-time.

### Completed Tasks
- [x] Created metric filter for Failed SSH Login Attempts (SSH Brute Force)
- [x] Created metric filter for Root Login Attempts
- [x] Created metric filter for Invalid SSH Users (User Enumeration)
- [x] Created metric filter for Port Scanning via VPC Flow Logs
- [x] Created CloudWatch alarm for SSH Brute Force (> 5 failures in 5 min)
- [x] Created CloudWatch alarm for Root Login Attempts (any occurrence)
- [x] Created CloudWatch alarm for Invalid User Enumeration (> 3 in 5 min)
- [x] Created CloudWatch alarm for Port Scanning (> 20 rejected connections in 1 min)
- [x] Added Phase 3 outputs for all metric filters and alarms

### File Structure Delivered
```
terraform/
├── main.tf                (Unchanged)
├── variables.tf           (Unchanged)
├── vpc.tf                 (Unchanged)
├── ec2.tf                 (Unchanged)
├── cloudwatch.tf          (Unchanged - Log Groups from Phase 2)
├── iam.tf                 (Unchanged)
├── outputs.tf             (UPDATED - Added 9 new Phase 3 outputs)
├── detections.tf          (NEW - Metric Filters + Alarms)
└── files/
    └── cloudwatch_agent_config.json.tpl  (Unchanged)
```

### Security Detections Implemented

| Detection | Source Log Group | Pattern | Threshold | Alarm Name |
|-----------|-----------------|---------|-----------|------------|
| SSH Brute Force | ec2/secure | "Failed password" | > 5 in 5 min | *-ssh-brute-force |
| Root Login Attempt | ec2/secure | "Failed password for root" | Any (> 0) | *-root-login-attempt |
| Invalid User Enumeration | ec2/secure | "Invalid user" | > 3 in 5 min | *-invalid-user-enumeration |
| Port Scanning | vpc/flow-logs | action="REJECT" | > 20 in 1 min | *-port-scan-detected |

### Metric Filter Patterns Explained

**1. Failed SSH Login (`"Failed password"`):**
- Matches any line containing the literal text "Failed password"
- Captures both failed password for valid and invalid users
- Amazon Linux /var/log/secure format: `sshd[PID]: Failed password for [user] from [IP] port [port] ssh2`

**2. Root Login Attempt (`"Failed password for root"`):**
- More specific pattern targeting root user explicitly
- Any attempt to authenticate as root is suspicious
- Amazon Linux format: `sshd[PID]: Failed password for root from [IP] port [port] ssh2`

**3. Invalid User (`"Invalid user"`):**
- Matches login attempts with non-existent usernames
- Indicates attacker reconnaissance/user enumeration
- Amazon Linux format: `sshd[PID]: Invalid user [username] from [IP] port [port]`

**4. Port Scan (VPC Flow Logs `action="REJECT"`):**
- Uses positional space-separated filter for VPC Flow Log default format
- Captures all REJECT actions (blocked by Security Group or NACL)
- High volume indicates port scanning or brute force at network level

### Alarm Thresholds Justification

| Alarm | Threshold | Period | Rationale |
|-------|-----------|--------|-----------|
| SSH Brute Force | > 5 | 5 min | 5 failures in 5 minutes exceeds normal typo rate; indicates automated attack |
| Root Login | > 0 | 1 min | Root SSH should be disabled; ANY attempt is suspicious and warrants immediate attention |
| Invalid User | > 3 | 5 min | 3+ invalid users suggests systematic enumeration rather than honest mistake |
| Port Scan | > 20 | 1 min | 20+ rejected connections/minute indicates aggressive scanning; normal traffic rarely triggers this |

### CloudWatch Metrics Namespace
All custom metrics are published to: `{project_name}/{environment}/Security`

Metrics created:
- `FailedSSHLoginAttempts`
- `RootLoginAttempts`
- `InvalidSSHUserAttempts`
- `RejectedConnections`

### Safe Testing Procedures

**Test 1: SSH Brute Force Detection**
```bash
# From a machine OUTSIDE AWS (your local machine), attempt failed SSH logins
# Use incorrect password or non-existent user
for i in {1..10}; do
  ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 \
      -o PreferredAuthentications=password \
      fakeuser@<EC2_PUBLIC_IP> 2>/dev/null || true
  echo "Attempt $i completed"
done
# Wait 2-3 minutes, then check CloudWatch Alarms console
# Alarm should transition to "In Alarm" state
```

**Test 2: Root Login Attempt Detection**
```bash
# Single root login attempt should trigger the alarm
ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 \
    -o PreferredAuthentications=password \
    root@<EC2_PUBLIC_IP>
# Enter any password when prompted (will fail)
# Wait 1-2 minutes, check alarm state
```

**Test 3: Invalid User Detection**
```bash
# Try multiple non-existent users
for user in admin administrator test guest operator; do
  ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 \
      -o PreferredAuthentications=password \
      ${user}@<EC2_PUBLIC_IP> 2>/dev/null || true
done
# Wait 2-3 minutes, check alarm state
```

**Test 4: Port Scan Detection (Network Level)**
```bash
# WARNING: Only run from authorized source; may trigger ISP alerts
# Use nmap to scan multiple ports (will be rejected by Security Group)
nmap -Pn -p 1-100 <EC2_PUBLIC_IP>
# The Security Group only allows port 22, so all others will REJECT
# Wait 1-2 minutes, check alarm state
```

### Validation Commands
After running `terraform apply`, verify detections with:

```bash
# List all metric filters
aws logs describe-metric-filters \
  --log-group-name "/<project_name>/<environment>/ec2/secure" \
  --region <region>

aws logs describe-metric-filters \
  --log-group-name "/<project_name>/<environment>/vpc/flow-logs" \
  --region <region>

# List all alarms
aws cloudwatch describe-alarms \
  --alarm-name-prefix "<project_name>-<environment>" \
  --region <region>

# Check alarm states
aws cloudwatch describe-alarms \
  --alarm-name-prefix "<project_name>-<environment>" \
  --query "MetricAlarms[].{Name:AlarmName,State:StateValue}" \
  --output table \
  --region <region>
```

### Tuning Considerations
When running in production, consider adjusting:

1. **SSH Brute Force Threshold:**
   - Lower to 3 for more sensitive detection
   - Raise to 10 if legitimate users frequently mistype passwords

2. **Invalid User Threshold:**
   - Lower to 1-2 for high-security environments
   - Raise if automated systems probe with common usernames

3. **Port Scan Threshold:**
   - Lower to 10 for early warning
   - Raise to 50 if legitimate services cause false positives

4. **Evaluation Periods:**
   - Increase to 2-3 for sustained attack detection
   - Keep at 1 for immediate response

### Known Issues/Risks
- Alarms have no notification actions configured (SNS integration is Phase 4 scope)
- Metric filter patterns assume Amazon Linux /var/log/secure format
- VPC Flow Log filter assumes default format (not custom format)
- Port scan detection may have false positives from legitimate health checks
- Root login alarm may be noisy if internet-facing; consider IP allowlisting in future

### Explicitly NOT Complete (Forbidden until Phase 4+)
- SNS topics or subscriptions (Phase 4 scope)
- Alarm notification actions (Phase 4 scope)
- CloudWatch Dashboard (Phase 4 scope)
- Lambda functions for alert enrichment (Phase 4+ scope)
- S3 buckets for log storage (not in current scope)
- Automated response/remediation (future phases)
- IP allowlisting for alarms (future enhancement)

### Dependencies for Next Phase
Before proceeding to Phase 4, the user should:
1. Run `terraform plan` to validate Phase 3 changes
2. Run `terraform apply` to deploy metric filters and alarms
3. Test at least one detection to verify alarms trigger correctly
4. Review CloudWatch console to see custom metrics appearing
5. Confirm all 4 alarms are in "OK" state (not "INSUFFICIENT_DATA")

---

## Phase 4 - Alert Delivery and Enrichment
**Status:** Completed
**Date:** 2025-12-16

### Phase Goal
Implement alert delivery and enrichment infrastructure to notify security teams and provide contextual information about detected threats.

### Completed Tasks
- [x] Created SNS topic for centralized security alerts
- [x] Created SNS topic policy allowing CloudWatch Alarms to publish
- [x] Created email subscription to SNS topic (requires manual confirmation)
- [x] Updated all 4 CloudWatch alarms to send notifications to SNS topic
- [x] Created IAM role and policy for Lambda function (least privilege)
- [x] Developed Lambda function for alert enrichment in Python 3.11
- [x] Created Lambda function resource with CloudWatch Logs integration
- [x] Created Lambda permission for SNS invocation
- [x] Created SNS subscription for Lambda function
- [x] Added alert_email variable with validation
- [x] Added 7 new Phase 4 outputs

### File Structure Delivered
```
terraform/
├── main.tf                (Unchanged)
├── variables.tf           (UPDATED - Added alert_email variable)
├── vpc.tf                 (Unchanged)
├── ec2.tf                 (Unchanged)
├── cloudwatch.tf          (Unchanged)
├── iam.tf                 (UPDATED - Added Lambda IAM resources)
├── outputs.tf             (UPDATED - Added 7 Phase 4 outputs)
├── detections.tf          (UPDATED - Added alarm_actions to all 4 alarms)
├── sns.tf                 (NEW - SNS topic, policy, email subscription)
├── lambda.tf              (NEW - Lambda function, permission, subscription)
└── files/
    └── cloudwatch_agent_config.json.tpl  (Unchanged)

lambda/
└── alert_enrichment.py    (NEW - Lambda function code)
```

### New Resources Created

| Resource Type | Name Pattern | Purpose |
|---------------|--------------|---------|
| aws_sns_topic | security_alerts | Central notification hub for all security alerts |
| aws_sns_topic_policy | security_alerts | Allows CloudWatch Alarms to publish to topic |
| aws_sns_topic_subscription | email_alerts | Sends alerts to configured email address |
| aws_sns_topic_subscription | lambda_alerts | Triggers Lambda for alert enrichment |
| aws_iam_role | lambda_alert_enrichment | IAM role for Lambda execution |
| aws_iam_policy | lambda_alert_enrichment | Least privilege CloudWatch Logs write permissions |
| aws_lambda_function | alert_enrichment | Enriches alerts with geolocation and context |
| aws_lambda_permission | allow_sns | Allows SNS to invoke Lambda |
| aws_cloudwatch_log_group | lambda_alert_enrichment | Lambda execution logs with 30-day retention |

### Alert Flow Architecture

```
CloudWatch Alarm Triggered
        ↓
    SNS Topic
        ↓
    ┌───┴───┐
    ↓       ↓
  Email   Lambda
  Alert   Enrichment
            ↓
      CloudWatch Logs
    (Enriched Alerts)
```

### Lambda Function Capabilities

The alert enrichment Lambda function provides:

1. **IP Address Extraction**: Parses alarm messages to extract source IP addresses
2. **Geolocation Lookup**: Uses ip-api.com free service to determine:
   - Country
   - City
   - ISP
   - Organization
   - ASN
3. **Detection Classification**: Categorizes alerts by type:
   - SSH Brute Force Attack
   - Root Login Attempt
   - User Enumeration Attack
   - Port Scanning Activity
4. **Severity Determination**: Assigns severity levels:
   - CRITICAL (Root login attempts)
   - HIGH (Brute force, port scans)
   - MEDIUM (User enumeration)
   - LOW (Other)
5. **Response Recommendations**: Provides actionable steps based on detection type
6. **Structured Logging**: Outputs enriched data in JSON format to CloudWatch Logs

### Lambda IAM Policy (Least Privilege)

The Lambda function has minimal permissions:
- `logs:CreateLogGroup` - Only for its own log group
- `logs:CreateLogStream` - Only for its own log group
- `logs:PutLogEvents` - Only for its own log group

**No permissions for**:
- Modifying infrastructure
- Blocking IPs
- Updating Security Groups
- Accessing EC2 instances
- Reading other logs

Lambda is strictly read-only for enrichment purposes.

### Alarm Notification Configuration

All 4 CloudWatch alarms now send notifications to SNS:
1. SSH Brute Force → SNS → Email + Lambda
2. Root Login Attempt → SNS → Email + Lambda
3. Invalid User Enumeration → SNS → Email + Lambda
4. Port Scanning → SNS → Email + Lambda

### Testing Phase 4

**Step 1: Confirm Email Subscription**
```bash
# After terraform apply, check email for:
# Subject: "AWS Notification - Subscription Confirmation"
# Click "Confirm subscription" link
```

**Step 2: Trigger Test Alert**
```bash
# Trigger SSH brute force detection (from Phase 3 tests)
for i in {1..10}; do
  ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 \
      -o PreferredAuthentications=password \
      fakeuser@<EC2_PUBLIC_IP> 2>/dev/null || true
done

# Wait 2-3 minutes for alarm to trigger
```

**Step 3: Verify Alert Delivery**
```bash
# Check email inbox for alert notification
# Subject will contain alarm name

# Verify Lambda was invoked
aws logs tail /aws/lambda/<project>-<env>-alert-enrichment --follow

# Look for enriched alert JSON with geolocation data
```

**Step 4: Review Enriched Logs**
```bash
# View Lambda logs in CloudWatch console
# Navigate to: CloudWatch > Log Groups > /aws/lambda/<project>-<env>-alert-enrichment
# Look for [ALERT] entries with enriched data including:
# - Source IP addresses
# - Geolocation (country, city, ISP)
# - Severity level
# - Detection type
# - Recommended actions
```

### Validation Commands

```bash
# List SNS topics
aws sns list-topics --region <region>

# List SNS subscriptions
aws sns list-subscriptions-by-topic \
  --topic-arn <sns_topic_arn> \
  --region <region>

# List Lambda functions
aws lambda list-functions \
  --query "Functions[?contains(FunctionName, 'alert-enrichment')]" \
  --region <region>

# Invoke Lambda manually for testing
aws lambda invoke \
  --function-name <project>-<env>-alert-enrichment \
  --payload file://test_event.json \
  --region <region> \
  response.json

# View Lambda logs
aws logs tail /aws/lambda/<project>-<env>-alert-enrichment \
  --follow \
  --region <region>
```

### Known Issues/Risks

1. **Email Subscription Requires Manual Confirmation**
   - User must click confirmation link in email
   - Alerts will not be delivered to email until confirmed
   - Lambda enrichment will still work regardless

2. **Geolocation API Rate Limits**
   - ip-api.com has 45 requests/minute limit (free tier)
   - High alert volume may exceed rate limit
   - Lambda will log warning and continue without geolocation data

3. **Private IP Addresses**
   - Geolocation lookup skipped for private IPs (10.x.x.x, 192.168.x.x, etc.)
   - Lambda correctly identifies and handles private ranges

4. **Lambda Cold Starts**
   - First invocation after idle period may take 1-2 seconds
   - Subsequent invocations are faster (warm start)

5. **No Automated Response**
   - Lambda enriches alerts only, does not block or remediate
   - Manual action required by security team
   - This is by design per Phase 4 scope

### Tuning Considerations

**Email Alert Fatigue:**
- Consider adding SNS filter policies to reduce email volume
- Critical/High alerts → Email
- Medium/Low alerts → Lambda only

**Lambda Performance:**
- Increase memory (256MB → 512MB) if processing is slow
- Increase timeout (30s → 60s) if geolocation lookups timeout

**Geolocation Alternatives:**
- Consider MaxMind GeoIP2 for higher rate limits
- Or implement IP geolocation caching in DynamoDB

**Alert Enrichment Expansion:**
- Add threat intelligence lookup (AbuseIPDB, VirusTotal)
- Integrate with SIEM platform
- Add historical attack frequency analysis

### Explicitly NOT Complete (Future Enhancements)

Phase 4 does NOT include:
- CloudWatch Dashboard (visualization)
- Automated blocking/remediation
- S3 log archival for compliance
- Threat intelligence integration
- SIEM platform integration
- Slack/PagerDuty/Teams integration
- IP reputation checking beyond geolocation
- Historical attack trend analysis
- Custom SNS message formatting

These features can be added in future phases or iterations.

### Cost Impact of Phase 4

Phase 4 adds minimal cost (should remain within free tier):

| Service | Usage | Free Tier | Cost |
|---------|-------|-----------|------|
| SNS | ~100 notifications/month | 1M publishes | $0.00 |
| Lambda | ~100 invocations/month | 1M requests | $0.00 |
| Lambda | ~256MB, 5s avg duration | 400,000 GB-seconds | $0.00 |
| CloudWatch Logs (Lambda) | ~50MB/month | 5GB ingestion | $0.00 |

**Estimated Additional Cost:** $0.00 - $1.00/month

### Dependencies for Next Phase

Before proceeding to Phase 5 (if planned), ensure:
1. Run `terraform plan` to validate Phase 4 changes
2. Run `terraform apply` to deploy SNS, Lambda, and alarm updates
3. Confirm email subscription via AWS confirmation email
4. Test at least one detection to verify:
   - Email alert received
   - Lambda function invoked successfully
   - Enriched logs appear in CloudWatch
5. Review Lambda logs for any errors or warnings
6. Verify all 4 alarms have alarm_actions configured

---

## Phase 5 - [Not Started]
**Status:** Not Started
