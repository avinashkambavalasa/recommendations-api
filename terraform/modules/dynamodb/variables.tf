variable "table_name" {
  description = "dynamodb table name"
  type        = string
}

variable "hash_key" {
  description = "partition key attribute name"
  type        = string
}

variable "hash_key_type" {
  description = "partition key type (S, N or B)"
  type        = string
  default     = "S"
}

variable "range_key" {
  description = "sort key name. leave empty if you dont need one"
  type        = string
  default     = ""
}

variable "range_key_type" {
  description = "sort key type (S, N or B)"
  type        = string
  default     = "S"
}

variable "billing_mode" {
  description = "PAY_PER_REQUEST or PROVISIONED. on-demand is usually fine unless you have very predictable load"
  type        = string
  default     = "PAY_PER_REQUEST"
  validation {
    condition     = contains(["PAY_PER_REQUEST", "PROVISIONED"], var.billing_mode)
    error_message = "billing_mode must be PAY_PER_REQUEST or PROVISIONED."
  }
}

variable "read_capacity" {
  description = "provisioned read capacity units. only needed when billing_mode is PROVISIONED"
  type        = number
  default     = 5
}

variable "write_capacity" {
  description = "provisioned write capacity units. only needed when billing_mode is PROVISIONED"
  type        = number
  default     = 5
}

variable "table_class" {
  description = "STANDARD or STANDARD_INFREQUENT_ACCESS. use IA for tables you dont query often"
  type        = string
  default     = "STANDARD"
  validation {
    condition     = contains(["STANDARD", "STANDARD_INFREQUENT_ACCESS"], var.table_class)
    error_message = "table_class must be STANDARD or STANDARD_INFREQUENT_ACCESS."
  }
}

variable "ttl_enabled" {
  description = "enable TTL on the table"
  type        = bool
  default     = false
}

variable "ttl_attribute_name" {
  description = "attribute used for TTL expiry, should be epoch seconds"
  type        = string
  default     = "ttl"
}

variable "deletion_protection" {
  description = "prevents accidental table deletion. only set false when you actually want to destroy it"
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "kms key for encryption at rest. null falls back to aws-managed dynamodb key"
  type        = string
  default     = null
}

variable "additional_attributes" {
  description = "extra attributes needed by GSIs or LSIs beyond hash/range keys"
  type = list(object({
    name = string
    type = string
  }))
  default = []
}

variable "global_secondary_indexes" {
  description = "GSI definitions"
  type = list(object({
    name            = string
    hash_key        = string
    range_key       = optional(string)
    projection_type = optional(string)
    read_capacity   = optional(number)
    write_capacity  = optional(number)
  }))
  default = []
}

variable "local_secondary_indexes" {
  description = "LSI definitions. note: LSIs cant be added after table creation"
  type = list(object({
    name            = string
    range_key       = string
    projection_type = optional(string)
  }))
  default = []
}

variable "replica_regions" {
  description = "regions to replicate into for global tables. leave empty for single-region"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "tags for the table"
  type        = map(string)
  default     = {}
}
