variable "account_name" {
  description = "app name used in resource names and tags"
  type        = string
}

variable "app_env" {
  description = "environment name"
  type        = string
  default     = ""
}

variable "app_region" {
  description = "aws region"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "azs" {
  description = "AZs to spread subnets across"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "public subnet CIDRs"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "private subnet CIDRs"
  type        = list(string)
}

variable "database_subnet_cidrs" {
  description = "database subnet CIDRs"
  type        = list(string)
}

variable "enable_nat_gateway" {
  description = "create NAT gateways for private subnet internet access. off by default to keep this assessment low cost"
  type        = bool
  default     = false
}

variable "single_nat_gateway" {
  description = "share one NAT gateway across all private subnets instead of one per AZ"
  type        = bool
  default     = true
}

variable "common_tags" {
  description = "extra tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "flow_log_retention_days" {
  description = "how long to keep vpc flow log data in cloudwatch"
  type        = number
  default     = 365
}

variable "flow_log_kms_key_arn" {
  description = "kms key for flow log encryption. leave empty to use aws-managed key"
  type        = string
  default     = ""
}

variable "enable_flow_logs" {
  description = "enable vpc flow logs to cloudwatch. CIS 3.9 - should be on in prod"
  type        = bool
  default     = true
}
