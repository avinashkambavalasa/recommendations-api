data "aws_s3_object" "artifact" {
  count = local.use_s3_artifact ? 1 : 0

  bucket = var.lambda_artifact_bucket
  key    = var.lambda_artifact_key
}

locals {
  use_s3_artifact = var.lambda_artifact_bucket != "" && var.lambda_artifact_key != ""
}

resource "aws_lambda_function" "this" {
  function_name = var.lambda_function_name
  role          = var.lambda_role_arn

  package_type  = "Zip"
  runtime       = "python3.10"
  handler       = "app.handlers.restaurant.lambda_handler"
  architectures = ["arm64"]

  filename         = local.use_s3_artifact ? null : var.lambda_zip_path
  source_code_hash = local.use_s3_artifact ? null : var.lambda_source_code_hash
  s3_bucket        = local.use_s3_artifact ? var.lambda_artifact_bucket : null
  s3_key           = local.use_s3_artifact ? var.lambda_artifact_key : null
  publish          = true

  memory_size = var.memory_size
  timeout     = var.timeout_seconds
  kms_key_arn = var.kms_key_arn

  dead_letter_config {
    target_arn = var.dead_letter_queue_arn
  }

  reserved_concurrent_executions = var.reserved_concurrency >= 0 ? var.reserved_concurrency : null

  ephemeral_storage {
    size = var.ephemeral_storage_mb
  }

  dynamic "vpc_config" {
    for_each = length(var.private_subnet_ids) > 0 ? [1] : []
    content {
      subnet_ids         = var.private_subnet_ids
      security_group_ids = var.lambda_security_group_ids
    }
  }

  tracing_config {
    mode = "Active"
  }

  environment {
    variables = {
      RESTAURANT_TABLE_NAME = var.table_name
      SERVICE_TIMEZONE      = var.service_timezone
      LOG_LEVEL             = var.log_level
    }
  }

  tags = var.tags
}

resource "aws_lambda_alias" "stable" {
  name             = "stable"
  function_name    = aws_lambda_function.this.function_name
  function_version = aws_lambda_function.this.version
}
