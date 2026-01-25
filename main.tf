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
