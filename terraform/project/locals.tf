locals {
  name_prefix          = "${var.app_name}-${var.app_env}"

  default_tags = merge(var.common_tags, {
    AppName     = var.app_name
    Environment = var.app_env
    ManagedBy   = "terraform"
    Owner       = "varonis-team"
    Stack       = "recommendation assessment"
  })

  # Resolve which DynamoDB table the Lambda reads from.
  # Priority: explicit var, if not provided, then look for first table in dynamo_db map > "" (no DynamoDB).
  # Setting dynamodb_app_table_key is only needed when dynamo_db has multiple tables and you want a specific one — leave it "" to auto-pick the first.
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
}
