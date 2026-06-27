data "aws_caller_identity" "current" {}

data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "${path.module}/../../api"
  output_path = "${path.module}/.terraform/${local.lambda_function_name}.zip"
}

# keys used by the app and log storage

module "kms" {
  source = "../modules/kms"

  app_name = var.app_name
  app_env  = var.app_env
  tags     = local.default_tags
}

# small runtime config for the app

resource "aws_secretsmanager_secret" "config" {
  name                    = local.config_secret_name
  kms_key_id              = module.kms.secrets_key_arn
  recovery_window_in_days = 7

  tags = merge(local.default_tags, { Name = "${local.name_prefix}-config-secret" })
}

resource "aws_secretsmanager_secret_version" "config" {
  secret_id = aws_secretsmanager_secret.config.id
  secret_string = jsonencode({
    service_timezone = var.service_timezone
  })
}

module "logging" {
  source   = "../modules/logging"
  for_each = local.logging_key != null ? { (local.logging_key) = true } : {}

  app_name             = var.app_name
  app_env              = var.app_env
  audit_kms_key_arn    = module.kms.audit_key_arn
  logs_kms_key_arn     = module.kms.logs_key_arn
  retention_days       = var.log_retention_days
  object_lock_days     = var.audit_object_lock_days
  lambda_function_name = local.lambda_function_name
  tags                 = local.default_tags
}

resource "aws_sqs_queue" "lambda_dlq" {
  name                      = "${local.lambda_function_name}-dlq"
  message_retention_seconds = 1209600
  kms_master_key_id         = module.kms.logs_key_arn

  tags = merge(local.default_tags, { Name = "${local.lambda_function_name}-dlq" })
}

# permissions for the lambda

module "iam" {
  source = "../modules/iam"

  app_name              = var.app_name
  app_env               = var.app_env
  table_arn             = local.table_arn
  log_group_arn         = local.log_group_arn
  logs_kms_key_arn      = module.kms.logs_key_arn
  secrets_kms_key_arn   = module.kms.secrets_key_arn
  config_secret_arn     = aws_secretsmanager_secret.config.arn
  dead_letter_queue_arn = aws_sqs_queue.lambda_dlq.arn
  tags                  = local.default_tags
}

resource "aws_cloudwatch_log_group" "lambda_fallback" {
  count             = var.enable_logging ? 0 : 1
  name              = "/aws/lambda/${local.lambda_function_name}"
  retention_in_days = var.log_retention_days
  kms_key_id        = module.kms.logs_key_arn
  tags              = local.default_tags
}

resource "aws_cloudwatch_log_group" "api_access_fallback" {
  count             = var.enable_logging ? 0 : 1
  name              = "/aws/apigateway/${local.name_prefix}-http-api"
  retention_in_days = var.log_retention_days
  kms_key_id        = module.kms.logs_key_arn
  tags              = local.default_tags
}

# lambda function

module "lambda" {
  source = "../modules/lambda"

  lambda_function_name      = local.lambda_function_name
  lambda_role_arn           = module.iam.lambda_role_arn
  lambda_zip_path           = data.archive_file.lambda.output_path
  lambda_source_code_hash   = data.archive_file.lambda.output_base64sha256
  lambda_artifact_bucket    = var.lambda_artifact_bucket
  lambda_artifact_key       = var.lambda_artifact_key
  dead_letter_queue_arn     = aws_sqs_queue.lambda_dlq.arn
  kms_key_arn               = module.kms.logs_key_arn
  private_subnet_ids        = var.private_subnet_ids
  lambda_security_group_ids = length(var.private_subnet_ids) > 0 ? [aws_security_group.lambda[0].id] : []
  table_name                = local.table_name
  service_timezone          = var.service_timezone
  memory_size               = var.lambda_memory_size
  timeout_seconds           = var.lambda_timeout_seconds
  reserved_concurrency      = var.reserved_concurrency
  canary_weight             = var.canary_weight
  tags                      = local.default_tags
}

# public api entry point

module "api_gateway" {
  source = "../modules/api_gateway"

  app_name                 = var.app_name
  app_env                  = var.app_env
  lambda_alias_invoke_arn  = module.lambda.lambda_alias_invoke_arn
  lambda_function_name     = module.lambda.lambda_function_name
  lambda_alias_name        = module.lambda.lambda_alias_name
  api_access_log_group_arn = local.api_access_log_group_arn
  cors_allowed_origins     = var.cors_allowed_origins
  enable_waf               = var.enable_waf
  waf_rate_limit           = var.waf_rate_limit
  enable_bot_control       = var.enable_bot_control
  logs_kms_key_arn         = module.kms.logs_key_arn
  tags                     = local.default_tags
}

# only needed when lambda is attached to private subnets
resource "aws_security_group" "lambda" {
  count = length(var.private_subnet_ids) > 0 ? 1 : 0

  name        = "${local.name_prefix}-lambda-sg"
  description = "Lambda VPC attachment: HTTPS egress only"
  vpc_id      = var.vpc_id

  # lambda is invoked by api gateway, so no inbound rule is needed

  egress {
    description = "HTTPS to AWS service endpoints (DynamoDB, Secrets Manager, KMS, etc.)"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.default_tags, { Name = "${local.name_prefix}-lambda-sg" })

  lifecycle {
    create_before_destroy = true
  }
}

# send cloudwatch logs to the audit stream when logging is on

resource "aws_cloudwatch_log_subscription_filter" "api_access_to_firehose" {
  count = var.enable_logging ? 1 : 0

  name            = "${local.name_prefix}-api-access-to-firehose"
  log_group_name  = module.logging["enabled"].api_access_log_group_name
  filter_pattern  = ""
  destination_arn = module.logging["enabled"].firehose_arn
  role_arn        = module.logging["enabled"].cloudwatch_to_firehose_role_arn

  depends_on = [module.api_gateway]
}

resource "aws_cloudwatch_log_subscription_filter" "lambda_to_firehose" {
  count = var.enable_logging ? 1 : 0

  name            = "${local.name_prefix}-lambda-to-firehose"
  log_group_name  = module.logging["enabled"].lambda_log_group_name
  filter_pattern  = ""
  destination_arn = module.logging["enabled"].firehose_arn
  role_arn        = module.logging["enabled"].cloudwatch_to_firehose_role_arn

  depends_on = [module.api_gateway]
}

module "monitoring" {
  source   = "../modules/monitoring"
  for_each = local.monitoring_key != null ? { (local.monitoring_key) = true } : {}

  app_name             = var.app_name
  app_env              = var.app_env
  lambda_function_name = module.lambda.lambda_function_name
  api_id               = module.api_gateway.api_id
  ddb_table_name       = local.table_name
  alarm_email          = var.alarm_email
  sns_kms_key_arn      = module.kms.logs_key_arn
  tags                 = local.default_tags
}
