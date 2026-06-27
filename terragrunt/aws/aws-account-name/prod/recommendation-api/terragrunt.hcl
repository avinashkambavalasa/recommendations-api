include "root" {
  path = find_in_parent_folders()
}

locals {
  sources = read_terragrunt_config(find_in_parent_folders("sources.hcl"))
}

terraform {
  source = local.sources.locals.terraform_project_source
}

inputs = {
  app_name = "${basename(get_terragrunt_dir())}"

  # restaurant table
  dynamo_db = {
    restaurant-api = {
      restaurants = {
        hash_key            = "restaurant_id"
        hash_key_type       = "S"
        billing_mode        = "PAY_PER_REQUEST"
        deletion_protection = true
        global_secondary_indexes = [
          {
            name            = "style-index"
            hash_key        = "style"
            projection_type = "ALL"
          }
        ]
        additional_attributes = [
          { name = "style", type = "S" }
        ]
      }
    }
  }

  # use this only if there are multiple dynamodb tables
  # dynamodb_app_table_key = "restaurant-api-restaurants"

  lambda_memory_size     = 512
  lambda_timeout_seconds = 10
  service_timezone       = "UTC"
  log_retention_days     = 365
  audit_object_lock_days = 90
  config_secret_name     = "restaurant-api/config"

  # change this key for every release
  lambda_artifact_bucket = "lambda-artifact-s3-bucket-name"
  lambda_artifact_key    = "restaurants/recommendations-api-v1.0.0.zip"

  cors_allowed_origins = ["https://app.example.com"]

  reserved_concurrency = 20 # tune after real load testing

  enable_waf         = true
  waf_rate_limit     = 300
  enable_bot_control = true

  enable_logging    = true
  enable_monitoring = true
  enable_flow_logs  = true
}
