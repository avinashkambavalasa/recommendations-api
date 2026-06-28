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
  description = "private subnet ids for the lambda vpc attachment"
  type        = list(string)
  default     = []
}

variable "public_subnet_ids" {
  description = "public subnet ids, not used right now but good to have in state"
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


variable "lambda_artifact_bucket" {
  description = "s3 bucket where the lambda zip lives"
  type        = string
  default     = ""
}

variable "lambda_artifact_key" {
  description = "s3 key for the lambda zip. pin to a specific version on every deploy"
  type        = string
  default     = ""
}

variable "service_timezone" {
  description = "timezone passed to the lambda as an env var"
  type        = string
  default     = "UTC"
}

variable "enable_logging" {
  description = "create cloudwatch log groups, s3 audit bucket and firehose pipeline"
  type        = bool
  default     = true
}

variable "enable_monitoring" {
  description = "create cloudwatch alarms"
  type        = bool
  default     = true
}

variable "enable_flow_logs" {
  description = "reserved flag for VPC flow logs when this app owns networking"
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "how long to keep cloudwatch logs"
  type        = number
  default     = 365
}

variable "audit_object_lock_days" {
  description = "object lock retention for audit logs in s3. prevents deletion"
  type        = number
  default     = 90
}

variable "lambda_memory_size" {
  description = "lambda memory in MB"
  type        = number
  default     = 256
}

variable "lambda_timeout_seconds" {
  description = "lambda timeout in seconds"
  type        = number
  default     = 10
}

variable "config_secret_name" {
  description = "base name for the secrets manager secret that holds app config"
  type        = string
  default     = "app/config"
}

variable "common_tags" {
  description = "extra tags to merge into all resources"
  type        = map(string)
  default     = {}
}

variable "cors_allowed_origins" {
  description = "allowed CORS origins. dont put wildcard here in prod"
  type        = list(string)
}

variable "reserved_concurrency" {
  description = "reserved concurrency for lambda. -1 means unreserved. setting this caps scaling and limits blast radius if traffic spikes"
  type        = number
  default     = -1
}

variable "enable_waf" {
  description = "attach a WAF WebACL to the api gateway stage"
  type        = bool
  default     = true
}


variable "waf_rate_limit" {
  description = "max requests per IP in a 5-min window before WAF blocks it"
  type        = number
  default     = 1000
}

variable "enable_bot_control" {
  description = "enable bot control managed rule group. adds per-request WAF charges so keep off in dev"
  type        = bool
  default     = false
}

variable "alarm_email" {
  description = "optional email address for cloudwatch alarm notifications"
  type        = string
  default     = ""
}

variable "canary_weight" {
  description = "percent of traffic to route to latest lambda version for canary. 0 disables canary routing"
  type        = number
  default     = 0
}

variable "initial_restaurants" {
  description = "seed restaurants managed by terraform"
  type = list(object({
    restaurant_id = string
    name          = string
    style         = string
    address       = string
    open_hour     = string
    close_hour    = string
    vegetarian    = bool
    deliveries    = bool
  }))
  default = [
    {
      restaurant_id = "bella-roma"
      name          = "Bella Roma"
      style         = "Italian"
      address       = "99 Wherever Street, Somewhere"
      open_hour     = "09:00"
      close_hour    = "23:00"
      vegetarian    = true
      deliveries    = true
    },
    {
      restaurant_id = "seoul-garden"
      name          = "Seoul Garden"
      style         = "Korean"
      address       = "12 Market Lane, Somewhere"
      open_hour     = "11:00"
      close_hour    = "22:00"
      vegetarian    = true
      deliveries    = false
    },
    {
      restaurant_id = "late-bistro"
      name          = "Late Bistro"
      style         = "French"
      address       = "5 Station Road, Somewhere"
      open_hour     = "18:00"
      close_hour    = "02:00"
      vegetarian    = false
      deliveries    = true
    }
  ]
}

variable "domain_name" {
  description = "base domain name eg example.com. full hostname will be <app>.<env>.<domain>. leave empty to use the default api gateway url"
  type        = string
  default     = ""
}

variable "zone_id" {
  description = "route53 hosted zone id. leave empty and it will look up the zone by domain_name"
  type        = string
  default     = ""
}
