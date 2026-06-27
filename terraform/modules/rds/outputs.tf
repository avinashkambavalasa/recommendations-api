output "security_group_id" {
  description = "ID of the RDS security group. use this to attach extra ingress rules in the calling layer."
  value       = aws_security_group.this.id
}

output "db_url" {
  description = "RDS instance endpoint address."
  value       = aws_db_instance.this.address
}

output "db_port" {
  description = "RDS instance port."
  value       = aws_db_instance.this.port
}

output "db_identifier" {
  description = "RDS instance identifier."
  value       = aws_db_instance.this.identifier
}

output "db_engine" {
  description = "Database engine type."
  value       = aws_db_instance.this.engine
}

output "db_engine_version" {
  description = "Database engine version in use."
  value       = aws_db_instance.this.engine_version_actual
}

output "db_instance_class" {
  description = "RDS instance class."
  value       = aws_db_instance.this.instance_class
}

output "db_multi_az" {
  description = "Whether Multi-AZ is enabled."
  value       = aws_db_instance.this.multi_az
}

output "db_deletion_protection" {
  description = "Whether deletion protection is enabled."
  value       = aws_db_instance.this.deletion_protection
}

output "db_instance_status" {
  description = "Current status of the RDS instance."
  value       = aws_db_instance.this.status
}

output "db_secret_name" {
  description = "Secrets Manager secret name holding DB credentials."
  value       = aws_secretsmanager_secret.db.name
}

output "db_secret_arn" {
  description = "Secrets Manager secret ARN holding DB credentials."
  value       = aws_secretsmanager_secret.db.arn
}

output "read_replica_endpoint" {
  description = "Endpoint of the read replica, if created. Empty string otherwise."
  value       = length(aws_db_instance.read_replica) > 0 ? aws_db_instance.read_replica[0].address : ""
}

# Used to build the rds-db:connect IAM permission ARN:
# arn:aws:rds-db:<region>:<account>:dbuser:<resource_id>/<app_username>
output "db_resource_id" {
  description = "RDS DbiResourceId — required to scope the rds-db:connect IAM permission."
  value       = aws_db_instance.this.resource_id
}
