# 🏰 Project 3: Secure Multi-Tier Architecture with Defense-in-Depth

[![AWS](https://img.shields.io/badge/AWS-FF9900?style=flat-square&logo=amazonaws&logoColor=white)](https://aws.amazon.com/)
[![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=flat-square&logo=terraform&logoColor=white)](https://www.terraform.io/)
[![Security](https://img.shields.io/badge/Security-Defense_in_Depth-green?style=flat-square)](https://aws.amazon.com/architecture/well-architected/)

> **A production-grade AWS architecture implementing multiple layers of security controls, following AWS Well-Architected Framework best practices.**

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Architecture](#-architecture)
- [Security Layers](#-security-layers)
- [Features](#-features)
- [Prerequisites](#-prerequisites)
- [Deployment Guide](#-deployment-guide)
- [Security Controls](#-security-controls)
- [Compliance Mapping](#-compliance-mapping)
- [Monitoring & Alerting](#-monitoring--alerting)
- [Cost Optimization](#-cost-optimization)
- [Disaster Recovery](#-disaster-recovery)
- [Lessons Learned](#-lessons-learned)

---

## 🎯 Overview

### What This Project Does

This project implements a **secure, scalable, highly-available** three-tier web application architecture on AWS, demonstrating enterprise-grade security controls:

1. **Network Security**: Segmented VPC with public/private subnets across multiple AZs
2. **Perimeter Defense**: WAF, DDoS protection, TLS termination
3. **Compute Security**: Hardened EC2 instances, auto-scaling, no public access
4. **Data Security**: Encrypted RDS, automated backups, no public access
5. **Access Control**: Least-privilege IAM, Secrets Manager integration
6. **Monitoring**: CloudTrail, GuardDuty, Config, comprehensive logging

### Why This Matters

This architecture represents what you'd deploy for a real production workload that handles sensitive data. It addresses:

- **Compliance Requirements**: SOC 2, PCI-DSS, HIPAA considerations
- **Security Best Practices**: AWS Well-Architected Framework Security Pillar
- **Enterprise Standards**: Multi-AZ, encryption everywhere, audit logging

### Skills Demonstrated

| Category | Technologies & Concepts |
|----------|------------------------|
| Cloud Architecture | Multi-tier design, High Availability, Scalability |
| Network Security | VPC, Subnets, NACLs, Security Groups, WAF |
| Data Protection | Encryption at rest/transit, Key Management |
| Identity & Access | IAM Roles, Policies, Secrets Manager |
| Monitoring | CloudTrail, GuardDuty, Config, CloudWatch |
| Infrastructure as Code | Terraform modules, State management |

---

## 🏗️ Architecture

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                            INTERNET                                          │
└─────────────────────────────────┬────────────────────────────────────────────┘
                                  │
                                  ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                              AWS SHIELD                                      │
│                          (DDoS Protection)                                   │
└─────────────────────────────────┬────────────────────────────────────────────┘
                                  │
                                  ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                            AWS WAF                                           │
│              (SQL Injection, XSS, Rate Limiting Rules)                       │
└─────────────────────────────────┬────────────────────────────────────────────┘
                                  │
                                  ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                              VPC (10.0.0.0/16)                               │
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │                     PUBLIC SUBNETS (2 AZs)                             │ │
│  │  ┌─────────────────────────────────────────────────────────────────┐  │ │
│  │  │              APPLICATION LOAD BALANCER                          │  │ │
│  │  │                   (HTTPS only, TLS 1.2+)                        │  │ │
│  │  └─────────────────────────────┬───────────────────────────────────┘  │ │
│  │                                │                                      │ │
│  │  ┌────────────────┐    ┌───────┴────────┐    ┌────────────────┐      │ │
│  │  │  NAT Gateway   │    │                │    │  NAT Gateway   │      │ │
│  │  │    (AZ-1)      │    │                │    │    (AZ-2)      │      │ │
│  │  └───────┬────────┘    │                │    └───────┬────────┘      │ │
│  └──────────┼─────────────┼────────────────┼────────────┼───────────────┘ │
│             │             │                │            │                 │
│  ┌──────────┼─────────────┼────────────────┼────────────┼───────────────┐ │
│  │          │     PRIVATE SUBNETS (App Tier)            │               │ │
│  │          ▼             ▼                ▼            ▼               │ │
│  │  ┌─────────────────────────────────────────────────────────────────┐│ │
│  │  │              AUTO SCALING GROUP                                 ││ │
│  │  │  ┌──────────────┐              ┌──────────────┐                 ││ │
│  │  │  │     EC2      │              │     EC2      │                 ││ │
│  │  │  │  (App Server)│              │  (App Server)│                 ││ │
│  │  │  │   AZ-1       │              │   AZ-2       │                 ││ │
│  │  │  └──────────────┘              └──────────────┘                 ││ │
│  │  └─────────────────────────────────────────────────────────────────┘│ │
│  │          │                                          │               │ │
│  │          │    Security Group: Allow only from ALB   │               │ │
│  └──────────┼──────────────────────────────────────────┼───────────────┘ │
│             │                                          │                 │
│  ┌──────────┼──────────────────────────────────────────┼───────────────┐ │
│  │          │     PRIVATE SUBNETS (Data Tier)          │               │ │
│  │          ▼                                          ▼               │ │
│  │  ┌─────────────────────────────────────────────────────────────────┐│ │
│  │  │                     RDS (Multi-AZ)                              ││ │
│  │  │              ┌──────────────────────────┐                       ││ │
│  │  │              │  PostgreSQL (Encrypted)  │                       ││ │
│  │  │              │  - Encryption at rest    │                       ││ │
│  │  │              │  - Encryption in transit │                       ││ │
│  │  │              │  - Automated backups     │                       ││ │
│  │  │              └──────────────────────────┘                       ││ │
│  │  │    Security Group: Allow only from App Tier on port 5432       ││ │
│  │  └─────────────────────────────────────────────────────────────────┘│ │
│  └─────────────────────────────────────────────────────────────────────┘ │
│                                                                          │
│  ┌─────────────────────────────────────────────────────────────────────┐ │
│  │                    MONITORING & LOGGING                             │ │
│  │  - CloudTrail (API logging)                                        │ │
│  │  - VPC Flow Logs                                                   │ │
│  │  - CloudWatch Alarms                                               │ │
│  │  - AWS Config (compliance)                                         │ │
│  │  - GuardDuty (threat detection)                                    │ │
│  └─────────────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────────────┘
```

---

## 🛡️ Security Layers

### Defense-in-Depth Model

```
Layer 1: PERIMETER
├── AWS Shield (DDoS protection)
├── AWS WAF (Application firewall)
└── Route 53 (DNS with health checks)

Layer 2: NETWORK
├── VPC isolation
├── Public/Private subnet segregation
├── Network ACLs (stateless filtering)
├── Security Groups (stateful filtering)
└── VPC Flow Logs (network monitoring)

Layer 3: COMPUTE
├── Hardened AMIs
├── No SSH from internet (use SSM)
├── Auto-patching enabled
└── Instance IAM roles (no hardcoded keys)

Layer 4: DATA
├── Encryption at rest (KMS)
├── Encryption in transit (TLS)
├── Automated backups
├── Secrets Manager for credentials
└── No public database access

Layer 5: IDENTITY
├── Least-privilege IAM
├── Role-based access
└── No long-term credentials

Layer 6: MONITORING
├── CloudTrail (API audit)
├── GuardDuty (threat detection)
├── AWS Config (compliance)
└── CloudWatch (metrics/logs)
```

---

## ✨ Features

### High Availability

| Component | HA Strategy |
|-----------|-------------|
| Load Balancer | Multi-AZ, health checks |
| EC2 Instances | Auto Scaling across AZs |
| Database | Multi-AZ RDS deployment |
| NAT Gateway | One per AZ |

### Security Features

| Feature | Implementation |
|---------|---------------|
| DDoS Protection | AWS Shield Standard |
| Web Application Firewall | AWS WAF with managed rules |
| Encryption at Rest | KMS-managed keys |
| Encryption in Transit | TLS 1.2+ everywhere |
| Secrets Management | AWS Secrets Manager |

---

## 📋 Prerequisites

- AWS Account with admin access
- Terraform >= 1.0
- AWS CLI configured
- Understanding of networking basics

---

## 🚀 Deployment Guide

### Step 1: Clone and Configure

```bash
cd project-3-secure-architecture/terraform

# Copy and edit variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
```

### Step 2: Initialize and Deploy

```bash
# Initialize Terraform
terraform init

# Preview changes
terraform plan

# Apply (this will take 15-20 minutes)
terraform apply
```

### Step 3: Verify Deployment

```bash
# Get ALB DNS
ALB_DNS=$(terraform output -raw alb_dns_name)

# Test HTTPS
curl -I https://$ALB_DNS
```

---

## 🔐 Security Controls

### Network Security Groups

| Security Group | Inbound | From |
|----------------|---------|------|
| ALB | 443 (HTTPS) | 0.0.0.0/0 |
| Application | 8080 | ALB SG only |
| Database | 5432 | App SG only |

### WAF Rules

| Rule | Description | Action |
|------|-------------|--------|
| SQL Injection | AWS Managed Rule | Block |
| XSS | AWS Managed Rule | Block |
| Rate Limiting | > 2000 req/5min | Block |

### IAM Least Privilege

- EC2 instances use IAM roles (no access keys)
- Roles only have permissions they need
- Secrets retrieved from Secrets Manager at runtime

---

## 📊 Compliance Mapping

| Framework | Relevant Controls |
|-----------|------------------|
| SOC 2 | CC6.1, CC6.6, CC7.1 |
| CIS AWS | 1.x, 2.x, 3.x, 4.x |
| PCI-DSS | 1.3, 2.3, 3.4, 4.1 |

---

## 📈 Monitoring & Alerting

### CloudWatch Alarms

| Alarm | Threshold | Action |
|-------|-----------|--------|
| High CPU | > 80% for 5 min | Scale out, alert |
| 5xx Errors | > 10 in 5 min | Alert |
| Unhealthy Hosts | Any | Alert |
| GuardDuty Finding | HIGH/CRITICAL | Alert |

---

## 💰 Cost Optimization

### Estimated Monthly Cost

| Service | Est. Cost |
|---------|-----------|
| EC2 (2x t3.small) | ~$30 |
| RDS (db.t3.micro Multi-AZ) | ~$25 |
| ALB | ~$20 |
| NAT Gateway (2x) | ~$65 |
| WAF | ~$10 |
| Other | ~$25 |
| **Total** | **~$175/mo** |

### Cost Saving Tips

- Use Reserved Instances (30-60% savings)
- Single NAT Gateway for dev/test
- Spot instances for non-production

---

## 🔄 Disaster Recovery

| Metric | Target |
|--------|--------|
| RTO | < 1 hour |
| RPO | < 5 minutes |

### Backup Strategy

- RDS automated snapshots: 7 days retention
- Manual snapshots: 30 days
- Terraform state in S3 with versioning

---

## 📝 Lessons Learned

1. **Defense in Depth Works**: Multiple layers mean single failures don't compromise everything
2. **Least Privilege is Hard**: Start restrictive, add permissions as needed
3. **Logging is Critical**: Enable everything - you can't protect what you can't see
4. **Automation Reduces Errors**: IaC prevents manual misconfigurations

---

## 🔮 Future Improvements

- [ ] Add CloudFront for CDN and additional DDoS protection
- [ ] Implement AWS Security Hub for aggregated view
- [ ] Add Amazon Inspector for vulnerability assessments
- [ ] Multi-region active-passive for DR

---

## 📂 Project Structure

```
project-3-secure-architecture/
├── README.md
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── modules/
│       ├── vpc/
│       ├── alb/
│       ├── asg/
│       ├── rds/
│       ├── waf/
│       ├── iam/
│       └── monitoring/
├── scripts/
│   └── security_check.sh
└── docs/
    ├── architecture.png
    └── security-controls.md
```

---

## 🧹 Cleanup

```bash
terraform destroy
```

---

<p align="center">
  <b>Part of the <a href="../README.md">Cloud Security Portfolio</a></b>
</p>

<p align="center">
  <i>"Security is everyone's job, but architecture makes it achievable."</i>
</p>
