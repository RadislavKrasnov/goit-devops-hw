# Lesson-7 — Kubernetes, Helm & Autoscaling with Terraform (AWS)

## Overview

This project follows Infrastructure as Code (IaC) using **Terraform** on **AWS**.  
This is a modular Terraform structure that provisions:

- Remote Terraform state storage in **S3** with state locking via **DynamoDB**
- Network infrastructure using **VPC** with public and private subnets
- **NAT Gateway** for outbound internet access from private subnets
- **ECR (Elastic Container Registry)** for storing Docker images
- **AWS EKS** for Kubernetes cluster provisioning

---

## Project Structure

lesson-7/  
│  
├── main.tf                  # Root Terraform module  
├── backend.tf               # Remote state (S3 + DynamoDB)  
├── providers.tf             # Providers configuration  
├── outputs.tf               # Global outputs  
├── terraform.lock.hcl       # Provider lock file  
├── Dockerfile               # Django application Dockerfile  
├── README.md                # Documentation  
│  
├── modules/    
│   ├── s3-backend/          # Remote Terraform backend  
│   ├── vpc/                 # Networking (VPC, subnets, NAT)  
│   ├── ecr/                 # ECR repository  
│   └── eks/                 # Kubernetes (EKS) cluster  
│  
├── charts/  
│   └── django-app/  
│       ├── Chart.yaml  
│       ├── values.yaml              # Non-secret configuration  
│       ├── values.secret.yaml       # NOT committed (gitignored)  
│       └── templates/  
│           ├── deployment.yaml  
│           ├── service.yaml  
│           ├── configmap.yaml  
│           ├── secret.yaml  
│           └── hpa.yaml  
│  
└── app/                     # Django application source code  
  
---

## Prerequisites

- Terraform `>= 1.4`
- Docker
- AWS account
- AWS CLI configured (`aws configure`)
- kubectl
- Helm
- IAM user with permissions for:
  - S3
  - DynamoDB
  - VPC
  - EC2
  - ECR
  - EKS
  - IAM

---

## How to Run the Project

### 1 Initial setup (first run — without backend)

Terraform backend **must not be enabled** until S3 and DynamoDB are created.

```bash
cd lesson-7
terraform init
terraform plan
terraform apply
```

This will create:
- S3 bucket for Terraform state
- DynamoDB table for state locking
- VPC, subnets, Internet Gateway, NAT Gateway
- ECR repository
- EKS cluster with managed node group

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

### eks module
Create Kubernetes cluster in AWS EKS:
- Managed Node Groups
- Autoscaling
- Networking

Outputs:  
- Repository URL for Docker image pushes

---

### 2. Configure kubectl access to EKS
Install Kubectl by using [official documentation](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/)

```bash
aws eks update-kubeconfig \
  --region us-east-1 \
  --name lesson-7-eks

```
Verify:

```bash
kubectl get nodes
```

### 3. Docker Image Build & Push to ECR  
1. Authenticate Docker to ECR  

```bash
aws ecr get-login-password --region us-east-1 \
  | docker login --username AWS --password-stdin <ECR_REPOSITORY_URL>
```

2. Build and push Django image  

```bash
docker build -t django-app:latest .
docker tag django-app:latest <ECR_REPOSITORY_URL>:latest
docker push <ECR_REPOSITORY_URL>:latest
```

### 4. Helm Deployment  
Install Helm by following [official documentation](https://helm.sh/docs/intro/install#from-apt-debianubuntu)   
Install Metrics Server (required for HPA)  

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

Verify

```bash
kubectl top nodes
```

### 5. Deploy Django application via Helm

```bash
helm upgrade --install my-django charts/django-app \
  -f charts/django-app/values.yaml \
  -f charts/django-app/values.secret.yaml
```

### Environment Variables Management
ConfigMap
- Stores non-sensitive environment variables
- Committed to Git   

Secret
- Stores sensitive variables (e.g. database password)
- Defined in values.secret.yaml
- File is excluded via .gitignore

Application loads configuration using:

```yaml
envFrom:
  - configMapRef:
      name: my-django-config
  - secretRef:
      name: my-django-secret

```

Verification
Check Kubernetes resources

```bash
kubectl get pods
kubectl get svc
kubectl get hpa
```

Confirm env vars inside the container

```bash
kubectl exec -it <pod-name> -- printenv | grep POSTGRES
```

Access application

```bash
kubectl get svc my-django-django
```

Open the EXTERNAL-IP in browser.

Autoscaling (HPA)  

```bash
kubectl describe hpa my-django-django
```

