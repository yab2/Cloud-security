# =============================================================================
# Variables - Phase 1 Core Infrastructure
# =============================================================================
# All required variables for the security monitoring infrastructure.
# No default values for sensitive items; they must be provided via tfvars.
# =============================================================================

variable "aws_region" {
  description = "AWS region where resources will be deployed"
  type        = string
}

variable "project_name" {
  description = "Name of the project, used for resource naming and tagging"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH into the EC2 instance (e.g., your IP/32)"
  type        = string

  validation {
    condition     = can(cidrhost(var.allowed_ssh_cidr, 0))
    error_message = "The allowed_ssh_cidr must be a valid CIDR block (e.g., 203.0.113.10/32)."
  }
}

variable "instance_type" {
  description = "EC2 instance type for the monitored host"
  type        = string
  default     = "t2.micro"
}
