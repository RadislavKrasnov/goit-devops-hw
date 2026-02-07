variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "us-east-1"
}

variable "db_password" {
  description = "Master password for the DB"
  type        = string
  sensitive   = true
}
