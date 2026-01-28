# Flexible Terraform RDS Module (RDS / Aurora)

This repository contains a **production-oriented Terraform module** that can create either:

- **Standard Amazon RDS** instance (PostgreSQL / MySQL), or
- **Amazon Aurora** cluster (Aurora PostgreSQL / Aurora MySQL)

The choice is controlled by the variable:

- `use_aurora = true`  → create **Aurora Cluster + writer + read replicas**
- `use_aurora = false` → create **one aws_db_instance** (standard RDS)

In **both** cases the module automatically creates:
- **DB Subnet Group**
- **Security Group**
- **Parameter Group** (for the selected DB type)

---

## Project Structure

```

Project/
│
├── main.tf
├── providers.tf
├── variables.tf
├── outputs.tf
├── backend.tf  
├── modules/
│   ├── s3-backend/
│   ├── vpc/
│   ├── ecr/
│   ├── eks/
│   ├── rds/  
│   │   ├── rds.tf
│   │   ├── aurora.tf
│   │   ├── shared.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── jenkins/
│   └── argo_cd/
│
└── charts/
└── django-app/

````

---

## What This Module Does

### Switching logic
- `use_aurora = true`:
  - creates `aws_rds_cluster`
  - creates `aws_rds_cluster_instance` writer
  - creates `aws_rds_cluster_instance` readers (replicas)
  - creates `aws_rds_cluster_parameter_group`

- `use_aurora = false`:
  - creates `aws_db_instance`
  - creates `aws_db_parameter_group`

### Always created (both modes)
- `aws_db_subnet_group`
- `aws_security_group`

### Default DB parameters (can be overridden)
The module supports a map of parameters and provides a default set like:
- `max_connections`
- `log_statement`
- `work_mem`

---

## How to Run  

### 1) Install prerequisites
- Terraform (>= 1.5 recommended)
- AWS CLI
- Git

### 2) Configure AWS credentials
```bash
aws configure
aws sts get-caller-identity
````

### 3) Backend note (important)

If your `backend.tf` points to an S3 backend that does not exist yet, `terraform init` will fail.

**Option A (recommended for “from scratch”):** temporarily disable backend

```bash
mv backend.tf backend.tf.disabled
```

**Option B:** create S3/DynamoDB backend first and then enable it.

### 4) Provide DB password securely

Do **not** hardcode DB passwords in `main.tf`.

Create `terraform.tfvars` (do not commit it):

```hcl
db_password = "ChangeMe_123456!"
```

### 5) Terraform commands

```bash
terraform init
terraform plan
terraform apply
```

### 6) Destroy resources  

```bash
terraform destroy
```

---

## Module Usage Example (Root `main.tf`)

Below is an example of using the module with an existing `module.vpc`:

```hcl
module "rds" {
  source = "./modules/rds"

  name       = "myapp-db"
  use_aurora = false  # switch to true for Aurora

  # --- Standard RDS (used only if use_aurora=false) ---
  engine                     = "postgres"
  engine_version             = "17.2"
  parameter_group_family_rds = "postgres17"

  # --- Aurora (used only if use_aurora=true) ---
  engine_cluster                 = "aurora-postgresql"
  engine_version_cluster         = "15.3"
  parameter_group_family_aurora  = "aurora-postgresql15"
  aurora_replica_count           = 1

  # --- Common settings ---
  instance_class        = "db.t3.micro"
  allocated_storage     = 20
  db_name               = "myapp"
  username              = "postgres"
  password              = var.db_password

  # Networking from VPC module
  vpc_id              = module.vpc.vpc_id
  subnet_private_ids  = module.vpc.private_subnets
  subnet_public_ids   = module.vpc.public_subnets
  publicly_accessible = false

  # Standard RDS HA (only affects aws_db_instance)
  multi_az = false

  backup_retention_period = 7

  # Parameter group values (can override defaults)
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
```

---

## How to Switch DB Type (RDS and Aurora)

### Create standard RDS

```hcl
use_aurora = false
engine     = "postgres"  # or "mysql"
```

### Create Aurora cluster

```hcl
use_aurora = true
engine_cluster = "aurora-postgresql"  # or "aurora-mysql"
aurora_replica_count = 2
```

Then run:

```bash
terraform plan
terraform apply
```

---

## How to Change Engine / Version

### Standard RDS (Postgres example)

```hcl
engine         = "postgres"
engine_version = "17.2"
parameter_group_family_rds = "postgres17"
```

### Standard RDS (MySQL example)

```hcl
engine         = "mysql"
engine_version = "8.0.35"
parameter_group_family_rds = "mysql8.0"
```

### Aurora PostgreSQL example

```hcl
engine_cluster = "aurora-postgresql"
engine_version_cluster = "15.3"
parameter_group_family_aurora = "aurora-postgresql15"
```

### Aurora MySQL example

```hcl
engine_cluster = "aurora-mysql"
engine_version_cluster = "8.0.mysql_aurora.3.05.2"  # example, must be AWS-supported
parameter_group_family_aurora = "aurora-mysql8.0"
```

> Note: Aurora versions are AWS-managed and may differ from “native” MySQL/Postgres releases.

---

## How to Change Instance Class

```hcl
instance_class = "db.t3.micro"
```

Examples:

* `db.t3.micro` 
* `db.t3.medium`
* `db.r6g.large` 

---

## Module Variables 

### Core switch

* **`name`** *(string, required)*
  Base name used for identifiers (`myapp-db`, `myapp-db-cluster`, etc.)

* **`use_aurora`** *(bool, default: false)*
  `true` → Aurora cluster
  `false` → standard RDS instance

---

### Standard RDS variables (used when `use_aurora=false`)

* **`engine`** *(string, default: "postgres")*
  Standard RDS engine: `postgres` or `mysql`

* **`engine_version`** *(string, default: "17.2")*
  Standard RDS engine version

* **`parameter_group_family_rds`** *(string, default: "postgres17")*
  Parameter group family for RDS (must match engine/version)

* **`allocated_storage`** *(number, default: 20)*
  Storage size in GB (RDS only)

* **`multi_az`** *(bool, default: false)*
  Multi-AZ deployment for standard RDS

---

### Aurora variables (used when `use_aurora=true`)

* **`engine_cluster`** *(string, default: "aurora-postgresql")*
  `aurora-postgresql` or `aurora-mysql`

* **`engine_version_cluster`** *(string, default: "15.3")*
  Aurora engine version (AWS-supported)

* **`parameter_group_family_aurora`** *(string, default: "aurora-postgresql15")*
  Parameter group family for Aurora (must match engine/version)

* **`aurora_replica_count`** *(number, default: 1)*
  Number of Aurora read-only replicas (readers)

---

### Common DB variables (used in both modes)

* **`instance_class`** *(string, default: "db.t3.micro")*
  Instance class for RDS or Aurora instances

* **`db_name`** *(string, required)*
  Default database name

* **`username`** *(string, required)*
  Master username

* **`password`** *(string, required, sensitive)*
  Master password (use tfvars or secret manager)

* **`backup_retention_period`** *(number, default: 7)*
  Days to keep automatic backups

* **`parameters`** *(map(string), default includes max_connections/log_statement/work_mem)*
  DB parameters applied via parameter group

* **`tags`** *(map(string), default: {})*
  Tags applied to all resources

---

### Networking variables

* **`vpc_id`** *(string, required)*
  VPC where DB will be created

* **`subnet_private_ids`** *(list(string), required)*
  Private subnet IDs (recommended for DB)

* **`subnet_public_ids`** *(list(string), required)*
  Public subnet IDs (used only if publicly_accessible=true)

* **`publicly_accessible`** *(bool, default: false)*
  `false` → DB in private subnets (recommended)
  `true` → DB in public subnets (not recommended)

---

## Outputs

The module outputs values that work for both RDS and Aurora:

* **`endpoint`**
  Standard RDS: `aws_db_instance.endpoint`
  Aurora: `aws_rds_cluster.endpoint` (writer endpoint)

* **`engine_type`**
  `"rds"` or `"aurora"`

* **`security_group_id`**
  Security group created for DB

* **`subnet_group_name`**
  DB subnet group name

---
