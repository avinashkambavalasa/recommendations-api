variable "app_name" {
  description = "app name, used as prefix in resource names"
  type        = string
}

variable "app_env" {
  description = "environment (dev, stg, prod)"
  type        = string
}

variable "audit_kms_key_arn" {
  type = string
}

variable "logs_kms_key_arn" {
  type = string
}

variable "retention_days" {
  description = "how long to keep logs in s3 before expiry"
  type        = number
  default     = 365
}

variable "object_lock_days" {
  description = "object lock retention period in days. protects audit logs from deletion"
  type        = number
  default     = 90
}

variable "lambda_function_name" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
