locals {
  name_prefix = "${var.app_name}-${var.app_env}"
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "lambda_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    # Confused-deputy protection: only Lambda functions in this specific account
    # can assume this role — prevents cross-account privilege escalation.
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_iam_role" "lambda" {
  name               = "${local.name_prefix}-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
  tags               = var.tags
}

data "aws_iam_policy_document" "lambda" {
  statement {
    sid    = "DynamoRead"
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:Query",
      "dynamodb:Scan"
    ]
    resources = [var.table_arn, "${var.table_arn}/index/*"]
  }

  statement {
    sid    = "LogsWrite"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["${var.log_group_arn}:*"]
  }

  statement {
    sid    = "XRayWrite"
    effect = "Allow"
    actions = [
      "xray:PutTraceSegments",
      "xray:PutTelemetryRecords"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "KMSDecrypt"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]
    resources = [var.logs_kms_key_arn, var.secrets_kms_key_arn]
  }

  statement {
    sid       = "ReadAppSecret"
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [var.config_secret_arn]
  }

  # RDS IAM database authentication: Lambda generates a short-lived token
  # (15 min TTL) via rds-db:connect instead of using a stored password.
  # Only included when RDS instances are provisioned (db_resource_ids non-empty).
  dynamic "statement" {
    for_each = length(var.db_resource_ids) > 0 ? [1] : []
    content {
      sid     = "RDSIAMAuth"
      effect  = "Allow"
      actions = ["rds-db:connect"]
      resources = [
        for rid in var.db_resource_ids :
        "arn:aws:rds-db:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:dbuser:${rid}/${var.db_app_username}"
      ]
    }
  }

  statement {
    sid    = "VpcNetworking"
    effect = "Allow"
    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface",
      "ec2:AssignPrivateIpAddresses",
      "ec2:UnassignPrivateIpAddresses"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "lambda" {
  name   = "${local.name_prefix}-lambda-policy"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.lambda.json
}
