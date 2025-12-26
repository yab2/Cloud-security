# =============================================================================
# EC2 Infrastructure - Phase 1 Core Infrastructure + Phase 2 Logging
# =============================================================================
# Creates the EC2 instance and Security Group.
# AMI is retrieved via data source (Amazon Linux 2, no hardcoded AMI ID).
# Security Group restricts SSH to allowed_ssh_cidr only.
#
# Phase 2 additions:
# - IAM instance profile for CloudWatch Agent
# - User data script to install and configure CloudWatch Agent
# =============================================================================

# -----------------------------------------------------------------------------
# Data Source: Amazon Linux 2 AMI
# -----------------------------------------------------------------------------
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

# -----------------------------------------------------------------------------
# Security Group
# -----------------------------------------------------------------------------
resource "aws_security_group" "ec2" {
  name        = "${var.project_name}-${var.environment}-ec2-sg"
  description = "Security group for EC2 instance - SSH restricted to allowed CIDR"
  vpc_id      = aws_vpc.main.id

  # Ingress: SSH from allowed CIDR only
  ingress {
    description = "SSH from allowed CIDR"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  # Egress: Allow all outbound traffic
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-ec2-sg"
  }
}

# -----------------------------------------------------------------------------
# EC2 Instance
# -----------------------------------------------------------------------------
resource "aws_instance" "main" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.ec2.id]

  # Phase 2: IAM instance profile for CloudWatch Agent
  iam_instance_profile = aws_iam_instance_profile.ec2_cloudwatch_agent.name

  # Phase 2: User data script to install and configure CloudWatch Agent
  user_data                   = base64encode(local.ec2_user_data)
  user_data_replace_on_change = true

  tags = {
    Name = "${var.project_name}-${var.environment}-instance"
  }
}

# -----------------------------------------------------------------------------
# CloudWatch Agent Installation Script (Phase 2)
# -----------------------------------------------------------------------------
# This local generates the user_data script that:
# 1. Installs the CloudWatch Agent from Amazon's package
# 2. Writes the agent configuration file
# 3. Starts the agent with the configuration
# -----------------------------------------------------------------------------
locals {
  cloudwatch_agent_config = templatefile("${path.module}/files/cloudwatch_agent_config.json.tpl", {
    log_group_secure = aws_cloudwatch_log_group.ec2_secure.name
    log_group_system = aws_cloudwatch_log_group.ec2_system.name
  })

  ec2_user_data = <<-EOF
    #!/bin/bash
    set -e

    # Update system packages
    yum update -y

    # Install CloudWatch Agent
    yum install -y amazon-cloudwatch-agent

    # Write CloudWatch Agent configuration
    cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'CWCONFIG'
    ${local.cloudwatch_agent_config}
    CWCONFIG

    # Start CloudWatch Agent with the configuration
    /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
      -a fetch-config \
      -m ec2 \
      -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
      -s

    # Enable CloudWatch Agent to start on boot
    systemctl enable amazon-cloudwatch-agent
  EOF
}
