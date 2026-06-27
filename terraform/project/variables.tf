variable "app_name" {
  description = "service name, used as prefix for all resource names"
  type        = string
}

variable "app_env" {
  description = "environment (dev, stg, prod)"
  type        = string
}

variable "app_region" {
  description = "aws region to deploy into"
  type        = string
}


variable "vpc_id" {
  description = "vpc id to deploy into"
  type        = string
  default     = ""
}

variable "private_subnet_ids" {
  description = "private subnet ids"
  type        = list(string)
  default     = []
}

variable "public_subnet_ids" {
  description = "public subnet ids"
  type        = list(string)
  default     = []
}

variable "db_subnet_ids" {
  description = "db subnet ids for the RDS subnet group. need at least 2 if sql_db is set"
  type        = list(string)
  default     = []
}

variable "dynamo_db" {
  description = "two-level map of dynamodb tables to create. leave empty to skip. format: { namespace = { table-key = { schema } } }"
  type        = any
  default     = {}
}

variable "ext_rds_sg_cidr_block" {
  description = "cidrs that can hit the db port directly, eg vpn or bastion range. set to [] to disable"
  type        = list(string)
  default     = ["10.0.0.0/8"]
}

variable "sql_db" {
  description = <<-EOT
    Map of PostgreSQL RDS instances to create. Leave empty ({}) to skip.
    key is used in the instance identifier: <cluster>-<key>-rds. needs vpc_id and db_subnet_ids when non-empty.
  EOT
  type = map(object({
    databases                  = optional(list(string), [])
    port                       = optional(number, 5432)
    admin_user                 = optional(string, "postgresadmin")
    node_type                  = optional(string, "db.t4g.small")
    disk_size                  = optional(number, 20)
    max_disk_size              = optional(number, null)
    multi_az                   = optional(bool, false)
    deletion_protection        = optional(bool, true)
    apply_changes_immediately  = optional(bool, false)
    engine_version             = optional(string, "16.9")
    backup_retention_days      = optional(number, 7)
    storage_type               = optional(string, "gp3")
    storage_throughput         = optional(number, null)
    iops                       = optional(number, 0)
    monitoring_interval        = optional(number, 0)
    auto_minor_version_upgrade = optional(bool, true)
    auto_major_version_upgrade = optional(bool, false)
    read_replica               = optional(bool, false)
    read_replica_multi_az      = optional(bool, false)
    log_min_duration_statement = optional(number, -1)
    pg_force_ssl               = optional(number, 1)
  }))
  default = {}
}

variable "db_app_username" {
  description = "postgres username lambda connects as. this user needs the rds_iam role in postgres"
  type        = string
  default     = "app"
}

variable "dynamodb_app_table_key" {
  description = "key in the flattened dynamo_tables map that lambda reads from. defaults to first table if empty"
  type        = string
  default     = ""
}

variable "common_tags" {
  description = "extra tags to merge into all resources"
  type        = map(string)
  default     = {}
}
