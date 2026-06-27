locals {
  name_prefix          = "${var.app_name}-${var.app_env}"
  lambda_function_name = "${local.name_prefix}-api"
  config_secret_name   = var.config_secret_name != "" ? var.config_secret_name : "${local.name_prefix}/config"
  logging_key          = var.enable_logging ? "enabled" : null
  monitoring_key       = var.enable_monitoring ? "enabled" : null

  default_tags = merge(var.common_tags, {
    AppName     = var.app_name
    Environment = var.app_env
    ManagedBy   = "terraform"
    Owner       = "varonis-team"
    Stack       = "recommendation assessment"
  })

  # pick the table for lambda. set dynamodb_app_table_key only if there is more than one.
  resolved_table_key = (
    var.dynamodb_app_table_key != ""
    ? var.dynamodb_app_table_key
    : length(keys(local.dynamo_tables)) > 0 ? keys(local.dynamo_tables)[0] : ""
  )

  table_name = (
    local.resolved_table_key != "" && contains(keys(module.dynamodb_table), local.resolved_table_key)
    ? module.dynamodb_table[local.resolved_table_key].table_name
    : ""
  )
  table_arn = (
    local.resolved_table_key != "" && contains(keys(module.dynamodb_table), local.resolved_table_key)
    ? module.dynamodb_table[local.resolved_table_key].table_arn
    : ""
  )

  selected_cors_origin = contains(var.cors_allowed_origins, "*") ? "*" : try(var.cors_allowed_origins[0], "*")
  log_group_arn        = var.enable_logging ? module.logging["enabled"].lambda_log_group_arn : aws_cloudwatch_log_group.lambda_fallback[0].arn
  api_access_log_group_arn = (
    var.enable_logging
    ? module.logging["enabled"].api_access_log_group_arn
    : aws_cloudwatch_log_group.api_access_fallback[0].arn
  )
}
