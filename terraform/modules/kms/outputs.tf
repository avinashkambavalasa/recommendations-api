output "dynamodb_key_arn" {
  value = aws_kms_key.dynamodb.arn
}

output "logs_key_arn" {
  value = aws_kms_key.logs.arn
}

output "audit_key_arn" {
  value = aws_kms_key.audit.arn
}

output "secrets_key_arn" {
  value = aws_kms_key.secrets.arn
}
