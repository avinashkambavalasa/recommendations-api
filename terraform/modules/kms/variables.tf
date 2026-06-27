variable "app_name" {
  description = "app name, first segment of all resource names"
  type        = string
}

variable "app_env" {
  description = "environment (dev, stg, prod)"
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
