output "s3_bucket_name" {
    description = "S3 bucket name for Terraform state"
    value       = module.s3_backend.s3_bucket_name
}

output "s3_bucket_domain_name" {
    description = "S3 bucket domain name"
    value       = module.s3_backend.s3_bucket_domain_name
}

output "dynamodb_table_name" {
    description = "DynamoDB table name for Terraform locks"
    value       = module.s3_backend.dynamodb_table_name
}

output "vpc_id" {
    description = "VPC ID"
    value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
    description = "Public subnet IDs"
    value       = module.vpc.public_subnets
}

output "private_subnet_ids" {
    description = "Private subnet IDs"
    value       = module.vpc.private_subnets
}

output "nat_gateway_id" {
    description = "NAT Gateway ID"
    value       = module.vpc.nat_gateway_id
}

output "ecr_repository_url" {
    description = "ECR repository URL"
    value       = module.ecr.ecr_repository_url
}

output "eks_cluster_name" {
  value = module.eks.eks_cluster_name
}

output "eks_cluster_endpoint" {
  value = module.eks.eks_cluster_endpoint
}
