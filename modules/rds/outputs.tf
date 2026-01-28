output "engine_type" {
  description = "Engine type created: aurora or rds"
  value       = var.use_aurora ? "aurora" : "rds"
}

output "endpoint" {
  description = "DB endpoint (Aurora writer endpoint or standard RDS endpoint)"

  value = (var.use_aurora
    ? aws_rds_cluster.aurora[0].endpoint
    : aws_db_instance.standard[0].endpoint)
}

output "security_group_id" {
  description = "Security group id for DB"
  value       = aws_security_group.rds.id
}

output "subnet_group_name" {
  description = "Subnet group name for DB"
  value       = aws_db_subnet_group.default.name
}
