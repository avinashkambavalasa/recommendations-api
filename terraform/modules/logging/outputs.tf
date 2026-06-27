output "api_access_log_group_name" {
  value = aws_cloudwatch_log_group.api_access.name
}

output "api_access_log_group_arn" {
  value = aws_cloudwatch_log_group.api_access.arn
}

output "lambda_log_group_name" {
  value = aws_cloudwatch_log_group.lambda_app.name
}

output "lambda_log_group_arn" {
  value = aws_cloudwatch_log_group.lambda_app.arn
}

output "firehose_arn" {
  value = aws_kinesis_firehose_delivery_stream.audit.arn
}

output "audit_bucket_name" {
  value = aws_s3_bucket.audit.id
}

output "cloudwatch_to_firehose_role_arn" {
  value = aws_iam_role.cloudwatch_to_firehose.arn
}
