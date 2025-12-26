# 🛡️ Cloud Security Portfolio

[![AWS](https://img.shields.io/badge/AWS-FF9900?style=for-the-badge&logo=amazonaws&logoColor=white)](https://aws.amazon.com/)
[![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)](https://www.terraform.io/)
[![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com/)
[![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://www.python.org/)
[![Linux](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)](https://www.linux.org/)

> **Production-grade cloud security projects demonstrating AWS infrastructure, DevSecOps practices, and security engineering skills.**

---

## 👤 About Me

I'm a Cloud Security Engineer with hands-on experience building secure, scalable infrastructure. This portfolio demonstrates my practical skills with cloud technologies, security operations, and DevOps practices.

| | |
|---|---|
| 🎓 **Education** | B.S. Computer Science, Western Governors University |
| 📜 **Certifications** | CompTIA A+, CompTIA Security+ |
| 🎯 **Goal** | Cloud Security Engineer / Georgia Tech MS Cybersecurity |
| 📍 **Focus Areas** | AWS, Infrastructure as Code, Threat Detection, DevSecOps |

---

## 🏗️ Portfolio Projects

### [Project 1: Cloud Security Monitoring Lab (SOC-in-a-Box)](./project-1-security-monitoring/)

**A cloud-native Security Operations Center that detects threats in real-time.**

| Component | Technology |
|-----------|------------|
| Infrastructure | AWS VPC, EC2, CloudWatch |
| Log Collection | CloudWatch Agent, VPC Flow Logs |
| Threat Detection | Metric Filters, Pattern Matching |
| Alerting | SNS, Lambda (IP Geolocation) |
| IaC | Terraform |

**Key Features:**
- 🔍 Real-time SSH brute force detection
- 🌐 VPC Flow Log analysis for network anomalies
- 🚨 Automated alerting with IP enrichment
- 📊 CloudWatch dashboard for security metrics
- 🏗️ Fully automated deployment with Terraform

**Skills Demonstrated:** Network security, log analysis, threat detection, cloud monitoring, Infrastructure as Code

**Status:** ✅ Complete

[📂 View Project →](./project-1-security-monitoring/)

---

### [Project 2: Automated Vulnerability Management Pipeline](./project-2-vulnerability-pipeline/)

**A DevSecOps CI/CD pipeline that automatically scans for security vulnerabilities.**

| Component | Technology |
|-----------|------------|
| CI/CD | GitHub Actions |
| Secret Scanning | Gitleaks |
| IaC Security | tfsec, Checkov |
| Container Scanning | Trivy |
| Registry | AWS ECR |
| Reporting | S3, SNS |

**Key Features:**
- 🔐 Automated secret detection in code
- 🏗️ Infrastructure-as-Code security scanning
- 🐳 Container vulnerability assessment
- 🚦 Security gates that block unsafe deployments
- 📋 Comprehensive security reports

**Skills Demonstrated:** DevSecOps, vulnerability management, CI/CD, container security, shift-left security

**Status:** ✅ Complete

[📂 View Project →](./project-2-vulnerability-pipeline/)

---

### [Project 3: Secure Multi-Tier Architecture](./project-3-secure-architecture/)

**Production-grade AWS architecture implementing defense-in-depth security.**

| Component | Technology |
|-----------|------------|
| Network | Multi-AZ VPC, Public/Private Subnets |
| Compute | ALB, Auto Scaling Group, EC2 |
| Database | RDS PostgreSQL (Encrypted) |
| Security | WAF, Security Groups, NACLs |
| Access Control | IAM Roles, Secrets Manager |
| Monitoring | CloudTrail, GuardDuty, AWS Config |

**Key Features:**
- 🏰 Defense-in-depth with multiple security layers
- 🌐 WAF protection against OWASP Top 10
- 🔒 Encryption at rest and in transit
- 👤 Least-privilege IAM policies
- 📝 Comprehensive audit logging
- 🛡️ DDoS protection with AWS Shield

**Skills Demonstrated:** Cloud architecture, network segmentation, encryption, compliance, security monitoring

**Status:** ✅ Complete

[📂 View Project →](./project-3-secure-architecture/)

---

## 🛠️ Technical Skills

### Cloud Platforms
```
AWS Services: VPC, EC2, RDS, S3, IAM, CloudWatch, CloudTrail,
              GuardDuty, WAF, Lambda, SNS, Secrets Manager,
              ECR, ECS, Config, Systems Manager
```

### Infrastructure as Code
```
Terraform: Modules, State Management, Workspaces
```

### Security Tools
```
Scanning: Trivy, tfsec, Checkov, Gitleaks
Monitoring: CloudWatch, GuardDuty, AWS Config
Analysis: VPC Flow Logs, CloudTrail, Access Analyzer
```

### DevOps & Automation
```
CI/CD: GitHub Actions
Containers: Docker, ECR
Scripting: Python (Boto3), Bash
Version Control: Git, GitHub
```

### Operating Systems
```
Linux: Ubuntu, Amazon Linux 2
Administration: systemd, package management, networking
Security: File permissions, SSH hardening, firewall rules
```

---

## 📊 Project Status

| Project | Status | Completion |
|---------|--------|------------|
| Security Monitoring Lab | ✅ Complete | 100% |
| Vulnerability Pipeline | ✅ Complete | 100% |
| Secure Architecture | ✅ Complete | 100% |

---

## 🎓 Certifications

| Certification | Status | Date |
|---------------|--------|------|
| CompTIA A+ | ✅ Achieved | 2025 |
| CompTIA Security+ | ✅ Achieved | 2025 |
| AWS Solutions Architect Associate | 🔄 In Progress | Target: 2026 |

---

## 📈 What I Built & Learned

This portfolio represents my hands-on journey into cloud security engineering:

**Project 1 - Security Monitoring:**
- Designed VPC architecture with security-focused network segmentation
- Implemented real-time threat detection using CloudWatch metric filters
- Built automated alerting pipeline with Lambda enrichment
- Deployed entire infrastructure using Terraform

**Project 2 - Vulnerability Pipeline:**
- Created CI/CD pipeline with integrated security scanning
- Implemented shift-left security with automated gates
- Configured secret detection, IaC scanning, and container scanning
- Built reporting system for security findings

**Project 3 - Secure Architecture:**
- Architected multi-tier application with defense-in-depth
- Implemented WAF rules for OWASP Top 10 protection
- Configured encryption at rest and in transit
- Set up comprehensive monitoring with GuardDuty and Config

---

## 🚀 Getting Started

### Prerequisites

- AWS Account (Free Tier eligible)
- Terraform >= 1.0
- Docker
- Git
- Python 3.9+

### Quick Start

```bash
# Clone the repository
git clone https://github.com/yab2/cloud-portfolio.git
cd cloud-security-portfolio

# Choose a project
cd project-1-security-monitoring

# Configure your variables
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# Edit terraform.tfvars with your values

# Deploy
cd terraform
terraform init
terraform plan
terraform apply
```

---

## 📁 Repository Structure

```
cloud-security-portfolio/
├── README.md                          # This file
├── .gitignore                         # Security-focused gitignore
│
├── project-1-security-monitoring/     # SOC-in-a-Box
│   ├── README.md
│   ├── terraform/
│   ├── lambda/
│   ├── scripts/
│   └── docs/
│
├── project-2-vulnerability-pipeline/  # DevSecOps Pipeline
│   ├── README.md
│   ├── .github/workflows/
│   ├── app/
│   ├── terraform/
│   └── docs/
│
└── project-3-secure-architecture/     # Defense-in-Depth
    ├── README.md
    ├── terraform/
    ├── scripts/
    └── docs/
```

---

## 📫 Contact

- **GitHub:** https://github.com/yab2/cloud-portfolio
- **LinkedIn:** https://www.linkedin.com/in/yeabsira702
- **Email:** yab@duck.com

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

<p align="center">
  <i>Built with ☕ and determination</i>
</p>

<p align="center">
  <i>"Security is not a product, but a process." - Bruce Schneier</i>
</p>
