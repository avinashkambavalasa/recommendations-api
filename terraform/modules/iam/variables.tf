variable "app_name" {
  description = "app name, first segment of all resource names"
  type        = string
}

variable "app_env" {
  description = "environment (dev, stg, prod)"
  type        = string
}

variable "table_arn" {
  type = string
}

variable "log_group_arn" {
  type = string
}

variable "logs_kms_key_arn" {
  type = string
}

variable "secrets_kms_key_arn" {
  type = string
}

variable "config_secret_arn" {
  type = string
}

variable "db_resource_ids" {
  description = "RDS DbiResourceId values to scope the rds-db:connect permission. leave empty if no RDS is provisioned"
  type        = list(string)
  default     = []
}

variable "db_app_username" {
  description = "postgres username lambda connects as using IAM auth tokens. this user needs the rds_iam role granted in postgres"
  type        = string
  default     = "app"
}

variable "tags" {
  type    = map(string)
  default = {}
}
