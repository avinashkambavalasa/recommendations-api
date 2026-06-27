variable "lambda_function_name" {
  type = string
}

variable "lambda_role_arn" {
  type = string
}

variable "lambda_zip_path" {
  description = "local lambda zip path used when lambda_artifact_bucket is empty"
  type        = string
  default     = ""
}

variable "lambda_source_code_hash" {
  description = "base64 sha256 for the local lambda zip"
  type        = string
  default     = ""
}

variable "lambda_artifact_bucket" {
  description = "optional s3 bucket where the lambda zip lives"
  type        = string
  default     = ""
}

variable "lambda_artifact_key" {
  description = "optional s3 key for the lambda zip"
  type        = string
  default     = ""
}

variable "private_subnet_ids" {
  type    = list(string)
  default = []
}

variable "lambda_security_group_ids" {
  type    = list(string)
  default = []
}

variable "dead_letter_queue_arn" {
  description = "SQS queue ARN used by Lambda for failed async events"
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key ARN used to encrypt Lambda environment variables"
  type        = string
}

variable "table_name" {
  type = string
}

variable "service_timezone" {
  type    = string
  default = "UTC"
}

variable "log_level" {
  type    = string
  default = "INFO"
}

variable "memory_size" {
  type    = number
  default = 256
}

variable "timeout_seconds" {
  type    = number
  default = 10
}

variable "reserved_concurrency" {
  description = "max concurrent executions. -1 means unreserved"
  type        = number
  default     = -1
}

variable "ephemeral_storage_mb" {
  description = "/tmp size in MB, valid range is 512-10240"
  type        = number
  default     = 512
}

variable "canary_weight" {
  description = "percent of traffic (0-100) to route to the latest version for canary testing. 0 disables it"
  type        = number
  default     = 0

  validation {
    condition     = var.canary_weight >= 0 && var.canary_weight <= 100
    error_message = "canary_weight must be between 0 and 100."
  }
}

variable "tags" {
  type    = map(string)
  default = {}
}
