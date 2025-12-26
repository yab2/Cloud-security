# =============================================================================
# Project 1: Cloud Security Monitoring Lab - Phase 1 Core Infrastructure
# =============================================================================
# This file configures the Terraform provider and basic settings.
# Phase 1 establishes the minimal AWS foundation for future SOC capabilities.
# =============================================================================

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}
