variable "app_name" {
  description = "app name, used as prefix in resource names"
  type        = string
}

variable "app_env" {
  description = "environment name (dev, stg, prod)"
  type        = string
}

variable "lambda_alias_invoke_arn" {
  description = "invoke arn for the lambda alias integrated by api gateway"
  type        = string
}

variable "lambda_function_name" {
  description = "lambda function name for explicit invoke permissions"
  type        = string
}

variable "lambda_alias_name" {
  description = "lambda alias name used by api gateway invoke permissions"
  type        = string
}

variable "api_access_log_group_arn" {
  type = string
}

variable "logs_kms_key_arn" {
  description = "KMS key used to encrypt WAF log groups"
  type        = string
}

variable "cors_allowed_origins" {
  description = "allowed origins for CORS. dont use wildcard in prod"
  type        = list(string)
}

variable "enable_waf" {
  description = "attach WAF to the api gateway stage, enables rate limiting and managed rule sets"
  type        = bool
  default     = true
}

variable "waf_rate_limit" {
  description = "max requests per IP per 5-min window before WAF blocks it. tune based on actual traffic"
  type        = number
  default     = 1000
}

variable "enable_bot_control" {
  description = "enable Bot Control managed rule group. adds per-request WAF cost so keep off in dev"
  type        = bool
  default     = false
}

variable "tags" {
  type    = map(string)
  default = {}
}
