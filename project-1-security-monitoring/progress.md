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

## Phase 2 - [Not Started]
**Status:** Not Started

## Phase 3 - [Not Started]
**Status:** Not Started

## Phase 4 - [Not Started]
**Status:** Not Started

## Phase 5 - [Not Started]
**Status:** Not Started
