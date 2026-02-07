variable "name" {
  description = "Base name for DB resources"
  type        = string
}

variable "use_aurora" {
  description = "true -> create Aurora cluster; false -> create standard aws_db_instance"
  type        = bool
  default     = false
}


# Standard RDS settings

variable "engine" {
  description = "RDS engine"
  type        = string
  default     = "postgres"
}

variable "engine_version" {
  description = "RDS engine version"
  type        = string
  default     = "17.2"
}

variable "parameter_group_family_rds" {
  description = "Parameter group family for RDS"
  type        = string
  default     = "postgres17"
}

# Aurora settings

variable "engine_cluster" {
  description = "Aurora engine"
  type        = string
  default     = "aurora-postgresql"
}

variable "engine_version_cluster" {
  description = "Aurora version"
  type        = string
  default     = "17.7"
}

variable "parameter_group_family_aurora" {
  description = "Parameter group family for Aurora"
  type        = string
  default     = "aurora-postgresql17"
}

variable "aurora_replica_count" {
  description = "How many read replicas to create for Aurora"
  type        = number
  default     = 1
}

# Common DB settings

variable "instance_class" {
  description = "DB instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Storage in GB"
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Default database name"
  type        = string
}

variable "username" {
  description = "Master username"
  type        = string
}

variable "password" {
  description = "Master password"
  type        = string
  sensitive   = true
}

# Networking

variable "vpc_id" {
  description = "VPC id"
  type        = string
}

variable "subnet_private_ids" {
  description = "Private subnet IDs"
  type        = list(string)
}

variable "subnet_public_ids" {
  description = "Public subnet IDs"
  type        = list(string)
}

variable "publicly_accessible" {
  description = "If true: DB has public endpoint and uses public subnets"
  type        = bool
  default     = false
}

# RDS specific options

variable "multi_az" {
  description = "Standard RDS Multi-AZ"
  type        = bool
  default     = false
}

# Backup + parameters

variable "backup_retention_period" {
  description = "Backup retention days"
  type        = number
  default     = 7
}

variable "parameters" {
  description = "Map of DB parameters for parameter group"
  type        = map(string)

  default = {
    max_connections = "200"
    log_statement   = "none"
    work_mem        = "4096"
  }
}

variable "tags" {
  description = "Tags for resources"
  type        = map(string)
  default     = {}
}
