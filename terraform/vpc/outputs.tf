output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = values(aws_subnet.public)[*].id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = values(aws_subnet.private)[*].id
}

output "database_subnet_ids" {
  description = "Database subnet IDs"
  value       = values(aws_subnet.database)[*].id
}

output "flow_log_group_name" {
  description = "CloudWatch log group name for VPC Flow Logs."
  value       = var.enable_flow_logs ? aws_cloudwatch_log_group.flow_logs[0].name : null
}

output "nat_gateway_ids" {
  description = "NAT Gateway IDs (empty when enable_nat_gateway = false)."
  value       = [for ng in aws_nat_gateway.this : ng.id]
}
