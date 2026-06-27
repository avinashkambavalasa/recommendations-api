variable "app_name" {
  description = "app name, first segment of all resource names"
  type        = string
}

variable "app_env" {
  description = "environment (dev, stg, prod)"
  type        = string
}

variable "name" {
  description = "short identifier for this instance, eg primary or analytics. combined with app_name and app_env for resource names"
  type        = string
}

variable "vpc_id" {
  description = "vpc to put the rds sg in, needs to match the subnet group"
  type        = string
}

variable "source_security_group_id" {
  description = "sg id allowed to reach the db port (usually the lambda sg). null if caller isnt in a vpc"
  type        = string
  default     = null
}

variable "db_subnet_group_name" {
  description = "subnet group to place the instance in"
  type        = string
}

variable "engine_version" {
  description = "postgres engine version"
  type        = string
  default     = "16.9"
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t4g.small"
}

variable "allocated_storage" {
  description = "initial storage in GB"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "ceiling for storage autoscaling in GB. defaults to allocated + 10 if not set"
  type        = number
  default     = null
}

variable "admin_user" {
  description = "master db username"
  type        = string
  default     = "postgresadmin"
}

variable "port" {
  description = "db port"
  type        = number
  default     = 5432
}

variable "multi_az" {
  description = "enable multi-az standby for HA"
  type        = bool
  default     = false
}

variable "deletion_protection" {
  description = "prevent accidental deletion of the instance"
  type        = bool
  default     = true
}

variable "apply_immediately" {
  description = "apply changes immediately instead of during maintenance window. can cause a restart"
  type        = bool
  default     = false
}

variable "backup_retention_days" {
  description = "days to keep automated backups"
  type        = number
  default     = 7
}

variable "storage_type" {
  description = "storage type: gp2, gp3, io1 or io2"
  type        = string
  default     = "gp3"
  validation {
    condition     = contains(["gp2", "gp3", "io1", "io2"], var.storage_type)
    error_message = "storage_type must be one of: gp2, gp3, io1, io2."
  }
}

variable "storage_throughput" {
  description = "throughput in MiB/s for gp3 volumes (125-1000). ignored for other types"
  type        = number
  default     = null
}

variable "iops" {
  description = "provisioned IOPS. for gp3 range is 3000-16000, for io1/io2 up to 64000. 0 uses the default for the storage type"
  type        = number
  default     = 0
}

variable "monitoring_interval" {
  description = "enhanced monitoring interval in seconds. 0 disables it. valid values: 0 1 5 10 15 30 60"
  type        = number
  default     = 0
}

variable "auto_minor_version_upgrade" {
  description = "auto-apply minor version upgrades during maintenance window"
  type        = bool
  default     = true
}

variable "auto_major_version_upgrade" {
  description = "allow major version upgrades. coordinate with the team before enabling this"
  type        = bool
  default     = false
}

variable "read_replica" {
  description = "create a read replica in the same region"
  type        = bool
  default     = false
}

variable "read_replica_multi_az" {
  description = "enable multi-az on the read replica"
  type        = bool
  default     = false
}

variable "log_min_duration_statement" {
  description = "log queries slower than this threshold (ms). -1 turns it off"
  type        = number
  default     = -1
  validation {
    condition     = var.log_min_duration_statement == -1 || var.log_min_duration_statement > 0
    error_message = "log_min_duration_statement must be -1 (disabled) or a positive integer (ms threshold)."
  }
}

variable "pg_force_ssl" {
  description = "set rds.force_ssl. 1 = require ssl for all connections"
  type        = number
  default     = 1
}

variable "tags" {
  description = "tags for all resources"
  type        = map(string)
  default     = {}
}
