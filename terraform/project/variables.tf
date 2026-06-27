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
