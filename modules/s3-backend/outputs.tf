output "s3_bucket_name" {
    description = "S3 bucket name for Terraform state"
    value       = aws_s3_bucket.terraform_state.bucket
}

output "s3_bucket_arn" {
    description = "S3 bucket ARN"
    value       = aws_s3_bucket.terraform_state.arn
}

output "s3_bucket_domain_name" {
    description = "S3 bucket domain name"
    value       = aws_s3_bucket.terraform_state.bucket_domain_name
}

output "dynamodb_table_name" {
    description = "DynamoDB table name for Terraform locks"
    value       = aws_dynamodb_table.terraform_locks.name
}
