variable "app_name" {
  description = "app name, used as prefix in resource names"
  type        = string
}

variable "app_env" {
  description = "environment (dev, stg, prod)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC. pick something that doesnt conflict with peered networks"
  type        = string
  default     = "10.40.0.0/16"
}

variable "az_count" {
  description = "number of AZs to spread subnets across. 2 is usually enough"
  type        = number
  default     = 2
}

variable "tags" {
  type    = map(string)
  default = {}
}
