# Lesson-5 — Terraform AWS Infrastructure (IaC)

## Overview

This project follows Infrastructure as Code (IaC) using **Terraform** on **AWS**.  
This is a modular Terraform structure that provisions:

- Remote Terraform state storage in **S3** with state locking via **DynamoDB**
- Network infrastructure using **VPC** with public and private subnets
- **NAT Gateway** for outbound internet access from private subnets
- **ECR (Elastic Container Registry)** for storing Docker images

---

## Project Structure

lesson-5/
│  
├── main.tf # Root module: connects all submodules  
├── backend.tf # Terraform backend configuration (S3 + DynamoDB)  
├── providers.tf # Provider and Terraform version configuration  
├── outputs.tf # Root outputs  
├── README.md # Project documentation  
│  
├── modules/  
│ │  
│ ├── s3-backend/ # Remote state backend module  
│ │ ├── s3.tf  
│ │ ├── dynamodb.tf  
│ │ ├── variables.tf  
│ │ └── outputs.tf  
│ │  
│ ├── vpc/ # VPC and networking module  
│ │ ├── vpc.tf    
│ │ ├── routes.tf  
│ │ ├── variables.tf  
│ │ └── outputs.tf  
│ │  
│ └── ecr/ # ECR module  
│ ├── ecr.tf  
│ ├── variables.tf  
│ └── outputs.tf  
  
---

## Prerequisites

- Terraform `>= 1.4`
- AWS account
- AWS CLI configured (`aws configure`)
- IAM user with permissions for:
  - S3
  - DynamoDB
  - VPC
  - EC2
  - ECR

---

## How to Run the Project

### 1 Initial setup (first run — without backend)

Terraform backend **must not be enabled** until S3 and DynamoDB are created.

```bash
cd lesson-5
terraform init
terraform plan
terraform apply
```

This will create:
- S3 bucket for Terraform state
- DynamoDB table for state locking
- VPC, subnets, Internet Gateway, NAT Gateway
- ECR repository

### 2 Enable remote backend (S3)
After resources are created, configure backend.tf:

```hcl
terraform {
  backend "s3" {
    bucket         = "your-unique-s3-bucket-name"
    key            = "lesson-5/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
```

Reinitialize Terraform and migrate state:

```bash
terraform init -reconfigure
```

Confirm migration by typing yes.

### 3 Common Terraform Commands
```bash
terraform plan     # Preview infrastructure changes
terraform apply    # Apply changes
terraform destroy  # Remove all infrastructure
```

## Terraform Modules
### s3-backend module
Responsible for remote Terraform state management.  

Creates S3 bucket with:  
- Versioning enabled  
- Public access blocked  
- DynamoDB table for Terraform state locking    

Used to:  
- Store terraform.tfstate securely  
- Prevent concurrent state modification  

### vpc module
Creates full network infrastructure:  
- VPC with custom CIDR block    
- 3 public subnets  
- 3 private subnets  
- Internet Gateway (for public subnets)  
- NAT Gateway (for private subnets)  
- Route tables and associations  

This setup allows:
- Internet access for public resources
- Secure outbound-only internet access for private resources

### ecr module
Creates an Amazon Elastic Container Registry:  
- Private ECR repository  
- Image scanning on push enabled  
- Repository access policy  

Outputs:  
- Repository URL for Docker image pushes
