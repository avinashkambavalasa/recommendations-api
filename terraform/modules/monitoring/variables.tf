variable "app_name" {
  description = "app name, used as prefix in resource names"
  type        = string
}

variable "app_env" {
  description = "environment (dev, stg, prod)"
  type        = string
}

variable "lambda_function_name" {
  type = string
}

variable "api_id" {
  type = string
}

variable "ddb_table_name" {
  type = string
}

variable "alarm_email" {
  description = "email to subscribe to alerts. leave empty if routing through pagerduty or similar"
  type        = string
  default     = ""
}

variable "sns_kms_key_arn" {
  description = "kms key to encrypt the alerts SNS topic at rest"
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
