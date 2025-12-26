# =============================================================================
# Outputs - Phase 1 Core Infrastructure
# =============================================================================
# Exposes essential resource identifiers for validation and future phases.
# =============================================================================

output "ec2_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.main.public_ip
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public.id
}
