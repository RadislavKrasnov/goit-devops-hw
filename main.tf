module "s3_backend" {
    source      = "./modules/s3-backend"
    bucket_name = "radyslav-lesson-5-tfstate-001001"
    table_name  = "terraform-locks"
}

module "vpc" {
    source             = "./modules/vpc"
    vpc_cidr_block     = "10.0.0.0/16"
    public_subnets     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
    private_subnets    = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
    availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
    vpc_name           = "lesson-5-vpc"
}

module "rds" {
  source = "./modules/rds"

  name       = "myapp-db"
  use_aurora = false

  # Standard RDS settings
  engine                     = "postgres"
  engine_version             = "17.2"
  parameter_group_family_rds = "postgres17"

  # Aurora settings (used only when use_aurora=true)
  engine_cluster                = "aurora-postgresql"
  engine_version_cluster        = "17.7"
  parameter_group_family_aurora = "aurora-postgresql17"
  aurora_replica_count          = 1

  # Common settings
  instance_class        = "db.t3.medium"
  allocated_storage     = 20
  db_name               = "myapp"
  username              = "postgres"
  password              = var.db_password

  # Connect to YOUR existing VPC module outputs
  vpc_id              = module.vpc.vpc_id
  subnet_private_ids  = module.vpc.private_subnets
  subnet_public_ids   = module.vpc.public_subnets
  publicly_accessible = false

  # Standard RDS HA option (only for standard instance)
  multi_az = false

  backup_retention_period = 7

  # DB parameters
  parameters = {
    max_connections = "200"
    log_statement   = "none"
    work_mem        = "4096"
  }

  tags = {
    Environment = "dev"
    Project     = "lesson-db-module"
  }
}


module "ecr" {
    source       = "./modules/ecr"
    ecr_name     = "lesson-5-ecr"
    scan_on_push = true
}

module "eks" {
  source             = "./modules/eks"
  cluster_name       = "lesson-7-eks"
  cluster_version    = "1.34"
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnets
}

module "jenkins" {
  source    = "./modules/jenkins"
  namespace = "jenkins"
  chart_version = "5.8.10"
  depends_on = [module.eks]
}

module "argo_cd" {
  source        = "./modules/argo_cd"
  namespace     = "argocd"
  chart_version = "5.46.4"
  depends_on    = [module.eks]
}

module "monitoring" {
  source        = "./modules/monitoring"
  namespace     = "monitoring"
  chart_version = "81.4.2"
  depends_on    = [module.eks]
}
