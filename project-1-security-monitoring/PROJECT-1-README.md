# 🔍 Project 1: Cloud Security Monitoring Lab (SOC-in-a-Box)

[![AWS](https://img.shields.io/badge/AWS-FF9900?style=flat-square&logo=amazonaws&logoColor=white)](https://aws.amazon.com/)
[![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=flat-square&logo=terraform&logoColor=white)](https://www.terraform.io/)
[![Python](https://img.shields.io/badge/Python-3776AB?style=flat-square&logo=python&logoColor=white)](https://www.python.org/)

> **A cloud-native Security Operations Center (SOC) that monitors AWS infrastructure and detects security threats in real-time.**

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Architecture](#-architecture)
- [Features](#-features)
- [Prerequisites](#-prerequisites)
- [Quick Start](#-quick-start)
- [Detailed Setup](#-detailed-setup)
- [Security Detections](#-security-detections)
- [Testing the System](#-testing-the-system)
- [Monitoring Dashboard](#-monitoring-dashboard)
- [Cost Estimation](#-cost-estimation)
- [Cleanup](#-cleanup)
- [Lessons Learned](#-lessons-learned)
- [Future Improvements](#-future-improvements)

---

## 🎯 Overview

### What This Project Does

This project creates a miniature Security Operations Center on AWS that:

1. **Collects logs** from multiple sources (EC2 instances, VPC Flow Logs)
2. **Analyzes patterns** to detect security threats
3. **Alerts automatically** when suspicious activity is detected
4. **Enriches alerts** with contextual information (IP geolocation)

### Why This Matters

In real-world enterprise environments, security teams use SIEM (Security Information and Event Management) systems to detect threats. This project demonstrates the same concepts using native AWS services, showcasing:

- **Threat Detection**: Identifying brute force attacks, port scans, and unauthorized access
- **Log Analysis**: Processing and filtering security-relevant events
- **Incident Response**: Automated alerting and enrichment workflows
- **Infrastructure as Code**: Reproducible, auditable security infrastructure

### Skills Demonstrated

| Skill Category | Technologies |
|----------------|--------------|
| Cloud Infrastructure | AWS VPC, EC2, CloudWatch |
| Security Operations | Log analysis, threat detection, alerting |
| Automation | Lambda, SNS, CloudWatch Metric Filters |
| Infrastructure as Code | Terraform |
| Scripting | Python (Boto3), Bash |

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                              INTERNET                                    │
└─────────────────────────────────┬───────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                            AWS CLOUD                                     │
│  ┌───────────────────────────────────────────────────────────────────┐  │
│  │                           VPC (10.0.0.0/16)                       │  │
│  │                                                                    │  │
│  │   ┌─────────────────────────────────────────────────────────────┐ │  │
│  │   │                    Public Subnet                             │ │  │
│  │   │                                                              │ │  │
│  │   │   ┌──────────────┐          ┌──────────────┐                │ │  │
│  │   │   │     EC2      │          │   Internet   │                │ │  │
│  │   │   │  (Web/SSH)   │◄────────►│   Gateway    │                │ │  │
│  │   │   │              │          │              │                │ │  │
│  │   │   └──────┬───────┘          └──────────────┘                │ │  │
│  │   │          │                                                   │ │  │
│  │   └──────────┼───────────────────────────────────────────────────┘ │  │
│  │              │                                                      │  │
│  │              │ Logs                                                 │  │
│  │              ▼                                                      │  │
│  │   ┌──────────────────────────────────────────────────────────────┐ │  │
│  │   │                    CloudWatch Logs                            │ │  │
│  │   │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐          │ │  │
│  │   │  │  SSH Logs   │  │ Apache Logs │  │  VPC Flow   │          │ │  │
│  │   │  │ /var/log/   │  │  /var/log/  │  │    Logs     │          │ │  │
│  │   │  │   secure    │  │   httpd     │  │             │          │ │  │
│  │   │  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘          │ │  │
│  │   └─────────┼────────────────┼────────────────┼──────────────────┘ │  │
│  │             │                │                │                     │  │
│  │             └────────────────┼────────────────┘                     │  │
│  │                              ▼                                      │  │
│  │   ┌──────────────────────────────────────────────────────────────┐ │  │
│  │   │                   Metric Filters                              │ │  │
│  │   │  ┌───────────────┐ ┌───────────────┐ ┌───────────────┐       │ │  │
│  │   │  │ Failed SSH    │ │  Root Login   │ │  Port Scan    │       │ │  │
│  │   │  │ Attempts      │ │  Detection    │ │  Detection    │       │ │  │
│  │   │  └───────┬───────┘ └───────┬───────┘ └───────┬───────┘       │ │  │
│  │   └──────────┼─────────────────┼─────────────────┼────────────────┘ │  │
│  │              │                 │                 │                   │  │
│  │              └─────────────────┼─────────────────┘                   │  │
│  │                                ▼                                     │  │
│  │   ┌──────────────────────────────────────────────────────────────┐ │  │
│  │   │                   CloudWatch Alarms                           │ │  │
│  │   │     Threshold: > 5 failed attempts in 5 minutes               │ │  │
│  │   └──────────────────────────┬───────────────────────────────────┘ │  │
│  │                              │                                      │  │
│  │                              ▼                                      │  │
│  │   ┌──────────────────────────────────────────────────────────────┐ │  │
│  │   │                      SNS Topic                                │ │  │
│  │   │                 (Security Alerts)                             │ │  │
│  │   └───────────────────┬──────────────────────────────────────────┘ │  │
│  │                       │                                             │  │
│  │           ┌───────────┴───────────┐                                │  │
│  │           ▼                       ▼                                │  │
│  │   ┌─────────────┐         ┌─────────────┐                         │  │
│  │   │   Lambda    │         │    Email    │                         │  │
│  │   │  (Enrichment)│         │   Alerts    │                         │  │
│  │   │             │         │             │                         │  │
│  │   │ • IP Lookup │         │             │                         │  │
│  │   │ • Geo Info  │         │             │                         │  │
│  │   │ • Threat DB │         │             │                         │  │
│  │   └─────────────┘         └─────────────┘                         │  │
│  │                                                                    │  │
│  └────────────────────────────────────────────────────────────────────┘  │
│                                                                          │
│   ┌────────────────────────────────────────────────────────────────────┐│
│   │                    S3 Bucket (Log Archive)                         ││
│   │              Long-term storage for compliance                       ││
│   └────────────────────────────────────────────────────────────────────┘│
└──────────────────────────────────────────────────────────────────────────┘
```

---

## ✨ Features

### 🔍 Threat Detection Capabilities

| Detection Type | Description | Alert Threshold |
|----------------|-------------|-----------------|
| **SSH Brute Force** | Multiple failed SSH login attempts | > 5 failures in 5 min |
| **Root Login Attempts** | Any attempt to login as root | Any occurrence |
| **Successful Root Login** | Successful root access (suspicious) | Any occurrence |
| **Invalid User Attempts** | Login attempts for non-existent users | > 3 in 5 min |
| **Port Scanning** | Multiple connection attempts to different ports | > 20 ports in 1 min |
| **Unusual Outbound Traffic** | Large data transfers from EC2 | > 1GB in 1 hour |

### 📊 Monitoring Dashboard

- Real-time failed login counter
- Geographic distribution of attack sources
- Timeline of security events
- Top attacking IP addresses

### 🚨 Alert Enrichment

When an alert fires, the Lambda function enriches it with:
- IP geolocation (country, city, ISP)
- Threat intelligence lookup
- Historical attack frequency from that IP
- Recommended response actions

---

## 📋 Prerequisites

Before starting, ensure you have:

- [ ] AWS Account (Free Tier eligible)
- [ ] AWS CLI installed and configured
- [ ] Terraform >= 1.0 installed
- [ ] Git installed
- [ ] Your public IP address (for SSH security group)

### Verify Prerequisites

```bash
# Check AWS CLI
aws --version
aws sts get-caller-identity

# Check Terraform
terraform --version

# Get your public IP
curl -s ifconfig.me
```

---

## 🚀 Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/yab2/cloud-portfolio.git
cd cloud-security-portfolio/project-1-security-monitoring

# 2. Configure variables
cp terraform/terraform.tfvars.example terraform/terraform.tfvars

# 3. Edit terraform.tfvars with your values
# - Set your email for alerts
# - Set your IP for SSH access
# - Customize settings as needed

# 4. Deploy infrastructure
cd terraform
terraform init
terraform plan
terraform apply

# 5. Confirm SNS subscription (check your email)

# 6. Test the detection (see Testing section)
```

---

## 📚 Detailed Setup

### Step 1: Configure Variables

Edit `terraform/terraform.tfvars`:

```hcl
# Required
aws_region       = "us-east-1"
alert_email      = "your-email@example.com"
allowed_ssh_cidr = "YOUR.PUBLIC.IP/32"  # Get from: curl ifconfig.me

# Optional customization
project_name     = "security-monitoring"
environment      = "dev"
instance_type    = "t2.micro"  # Free tier
```

### Step 2: Deploy Infrastructure

```bash
cd terraform

# Initialize Terraform
terraform init

# Preview changes
terraform plan

# Apply (type 'yes' when prompted)
terraform apply
```

### Step 3: Verify Deployment

```bash
# Get outputs
terraform output

# You should see:
# - EC2 instance public IP
# - CloudWatch Log Group names
# - SNS Topic ARN
# - S3 bucket name
```

### Step 4: Confirm Email Subscription

1. Check your email for "AWS Notification - Subscription Confirmation"
2. Click "Confirm subscription"
3. You'll now receive security alerts

### Step 5: Verify Log Flow

```bash
# SSH into the instance
ssh -i ~/.ssh/your-key.pem ec2-user@<instance-ip>

# Generate some log entries
sudo tail -f /var/log/secure

# In CloudWatch Console:
# Navigate to CloudWatch > Log Groups > /security-monitoring/ssh-logs
# You should see log streams appearing
```

---

## 🎯 Security Detections

### Detection 1: SSH Brute Force

**Pattern:** Multiple failed password attempts from the same IP

**Metric Filter:**
```
[version, account, eni, source, destination, srcport, destport="22", protocol, packets, bytes, windowstart, windowend, action="REJECT", flowlogstatus]
```

**CloudWatch Alarm:**
- Threshold: > 5 occurrences in 5 minutes
- Action: Send to SNS topic

**Real-world significance:** Brute force attacks are one of the most common attack vectors. Detecting them early prevents unauthorized access.

---

### Detection 2: Root Login Attempts

**Pattern:** Any "Failed password for root" in auth logs

**Metric Filter:**
```
{ $.message = "*Failed password for root*" }
```

**CloudWatch Alarm:**
- Threshold: > 0 occurrences
- Action: Immediate alert

**Real-world significance:** Root login attempts indicate targeted attacks. Most systems disable root SSH login, so any attempt is suspicious.

---

### Detection 3: Invalid User Enumeration

**Pattern:** Login attempts for users that don't exist

**Metric Filter:**
```
{ $.message = "*Invalid user*" }
```

**CloudWatch Alarm:**
- Threshold: > 3 in 5 minutes
- Action: Send alert

**Real-world significance:** Attackers often probe for common usernames. Multiple invalid user attempts indicate reconnaissance activity.

---

## 🧪 Testing the System

### Test 1: Trigger SSH Brute Force Alert

```bash
# From your local machine, intentionally fail SSH logins
# (Use wrong password or non-existent user)

for i in {1..10}; do
  ssh -o StrictHostKeyChecking=no -o PasswordAuthentication=yes \
      fakeuser@<instance-ip> 2>/dev/null
  echo "Attempt $i"
done

# Wait 2-3 minutes, then check:
# 1. CloudWatch Metrics for the spike
# 2. Your email for the alert
```

### Test 2: Verify Log Collection

```bash
# SSH into instance
ssh -i ~/.ssh/your-key.pem ec2-user@<instance-ip>

# Generate some log entries
logger -p auth.info "Test security log entry"

# Check CloudWatch Logs console
# New entries should appear within 1-2 minutes
```

### Test 3: Verify Alert Enrichment

When you receive an alert email, verify it contains:
- Source IP address
- Geolocation information
- Number of attempts
- Timestamp
- Recommended actions

---

## 📊 Monitoring Dashboard

### CloudWatch Dashboard Components

After deployment, access the CloudWatch Dashboard to see:

1. **Failed Login Attempts** - Line graph showing attempts over time
2. **Top Attacking IPs** - Table of most frequent offenders
3. **Geographic Distribution** - Map showing attack origins
4. **Alert Status** - Current alarm states

### Accessing the Dashboard

1. Navigate to AWS Console > CloudWatch > Dashboards
2. Select "security-monitoring-dashboard"
3. Set time range as needed

---

## 💰 Cost Estimation

This project is designed to stay within AWS Free Tier limits.

| Service | Free Tier | This Project | Monthly Cost |
|---------|-----------|--------------|--------------|
| EC2 (t2.micro) | 750 hrs/mo | ~720 hrs | $0.00 |
| CloudWatch Logs | 5GB ingestion | ~1GB | $0.00 |
| CloudWatch Alarms | 10 alarms | 5 alarms | $0.00 |
| Lambda | 1M requests | ~1000 | $0.00 |
| SNS | 1M publishes | ~100 | $0.00 |
| S3 | 5GB storage | ~1GB | $0.00 |

**Estimated Monthly Cost:** $0.00 - $5.00

> ⚠️ **Note:** Costs may vary based on log volume and alert frequency. Set up billing alerts at $5 to be safe.

---

## 🧹 Cleanup

To avoid any charges, destroy the infrastructure when done:

```bash
cd terraform

# Destroy all resources
terraform destroy

# Type 'yes' when prompted

# Verify in AWS Console that resources are deleted
```

### Manual Cleanup (if needed)

If Terraform destroy fails:

1. EC2 > Terminate instance
2. VPC > Delete VPC (will delete subnets, IGW, etc.)
3. CloudWatch > Delete Log Groups
4. S3 > Empty and delete bucket
5. SNS > Delete topic
6. Lambda > Delete function

---

## 📝 Lessons Learned

### Technical Insights

1. **CloudWatch Agent Configuration**: The agent config file format is crucial. JSON syntax errors silently fail.

2. **Metric Filter Patterns**: CloudWatch metric filter patterns have specific syntax. Test patterns in the console before committing.

3. **IAM Permissions**: Lambda needs explicit permissions to write to CloudWatch Logs. Always use least privilege.

4. **VPC Flow Logs**: Default format vs custom format significantly affects filtering capability.

### Security Insights

1. **Baseline is Essential**: Establishing normal traffic patterns is critical for anomaly detection.

2. **Alert Fatigue is Real**: Too many false positives lead to ignored alerts. Tune thresholds carefully.

3. **Defense in Depth**: Monitoring is one layer. Combine with proper security groups, NACLs, and IAM policies.

---

## 🔮 Future Improvements

### Short-term Enhancements

- [ ] Add GuardDuty integration for ML-based threat detection
- [ ] Implement automated response (block IPs via Lambda + NACL)
- [ ] Add web application log analysis (detect SQLi, XSS patterns)
- [ ] Create Slack integration for alerts

### Long-term Vision

- [ ] Multi-account monitoring with AWS Organizations
- [ ] Integration with SIEM platform (Splunk, ELK)
- [ ] Machine learning anomaly detection with SageMaker
- [ ] Compliance reporting (SOC 2, PCI-DSS)

---

## 📂 Project Structure

```
project-1-security-monitoring/
├── README.md                 # This file
├── terraform/
│   ├── main.tf              # Main infrastructure
│   ├── variables.tf         # Variable definitions
│   ├── outputs.tf           # Output values
│   ├── vpc.tf               # VPC configuration
│   ├── ec2.tf               # EC2 instance
│   ├── cloudwatch.tf        # CloudWatch resources
│   ├── lambda.tf            # Lambda function
│   ├── sns.tf               # SNS configuration
│   ├── s3.tf                # S3 bucket for logs
│   ├── iam.tf               # IAM roles and policies
│   └── terraform.tfvars.example
├── lambda/
│   └── alert_enrichment.py  # Lambda function code
├── scripts/
│   ├── test_brute_force.sh  # Test script
│   └── cloudwatch_agent_config.json
├── docs/
│   ├── architecture.png     # Architecture diagram
│   ├── dashboard.png        # Dashboard screenshot
│   └── alert_example.png    # Sample alert
└── screenshots/
    └── ...                  # Project screenshots
```

---

## 🤝 Contributing

This is a portfolio project, but suggestions are welcome! Feel free to:

1. Open an issue for bugs or suggestions
2. Submit a pull request with improvements
3. Star the repo if you found it helpful

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](../LICENSE) file for details.

---

## 🙏 Acknowledgments

- AWS Well-Architected Framework - Security Pillar
- SANS Institute - Cloud Security Resources
- CloudWatch Documentation and Examples

---

<p align="center">
  <b>Part of the <a href="../README.md">Cloud Security Portfolio</a></b>
</p>

<p align="center">
  <i>"Detection is the first step to protection."</i>
</p>
