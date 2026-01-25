# Lesson 8–9 — Full CI/CD with Jenkins, Terraform, Helm & Argo CD (AWS EKS)

## Overview

This project demonstrates a **full CI/CD pipeline** using modern **DevOps** and **GitOps** practices.

The solution combines:

- **Terraform** — Infrastructure as Code (AWS)
- **Amazon EKS** — Kubernetes cluster
- **Amazon ECR** — Docker image registry
- **Helm** — Kubernetes package management
- **Jenkins** — Continuous Integration (CI)
- **Argo CD** — GitOps-based Continuous Deployment (CD)

The pipeline works **without manual deployment steps**:

- Code change → Jenkins builds Docker image
- Image is pushed to Amazon ECR
- Helm chart is updated in Git
- Argo CD detects Git change and deploys automatically

---

## High-Level CI/CD Architecture
```
Developer
    |
    | git push (application code)
    v
GitHub (Repo 1: infra + app)
    |
    | Jenkinsfile
    v
Jenkins (Kubernetes Agent)
    | 
    | • Build Docker image
    | • Push to ECR
    | • Update Helm values.yaml
    v
GitHub (Repo 2: Helm charts)
    |
    | GitOps
    v
Argo CD
    |
    | Auto-sync
    v
Kubernetes (EKS)
```

---

## Jenkins Kubernetes Agent  

Kubernetes Agent definition  in Jenkins UI (Manage Jenkins → Clouds → New cloud):  

Cloud configuration (cluster URL, credentials, namespace)  
→ Defined manually in Jenkins  

---

## Repositories

### Repo 1 — Infrastructure & Application

[Repo link](https://github.com/RadislavKrasnov/goit-devops-hw/tree/lesson-8-9)  

Contains:
- Terraform root and modules
- Jenkinsfile
- Dockerfile
- Django application source code

### Repo 2 — Helm Charts (GitOps)

[Repo link](https://github.com/RadislavKrasnov/goit-devops-charts/tree/master)

Contains:
- Helm chart for Django application only
- Watched by Argo CD

**Important:**  
Dockerfile and application code are **NOT stored** in Repo 2.

---

## Project Structure (Repo 1)
```
lesson-8-9/  
├── main.tf  
├── backend.tf  
├── providers.tf  
├── outputs.tf  
├── variables.tf  
├── Jenkinsfile  
├── Dockerfile  
├── app/ # Django application  
├── modules/  
│ ├── s3-backend/  
│ ├── vpc/  
│ ├── ecr/  
│ ├── eks/  
│ ├── jenkins/  
│ └── argo_cd/  
└── README.md  
```

---

## Project Structure (Repo 2)

```
charts/  
└── django-app/  
    ├── Chart.yaml  
    ├── values.yaml  
    └── templates/  
        ├── deployment.yaml  
        ├── service.yaml  
        ├── configmap.yaml  
        └── hpa.yaml  
```
---

## Prerequisites

- Terraform `>= 1.4`
- AWS account
- AWS CLI (`aws configure`)
- kubectl
- Helm
- Docker (for local builds if needed)
- IAM user with access to:
  - VPC
  - EC2
  - EKS
  - ECR
  - S3
  - DynamoDB
  - IAM

---

## How to Use Terraform (Infrastructure Deployment)

### 1. Configure AWS CLI

```bash
aws configure
aws sts get-caller-identity
```

### 2. Initial Terraform Run (local state)

```bash
terraform init
terraform apply
```

This creates:  
- S3 bucket + DynamoDB for Terraform backend  
- VPC with public/private subnets  
- NAT Gateway  
- ECR repository  
- EKS cluster  
- Jenkins (via Helm)  
- Argo CD (via Helm)  

--- 

### 3. Enable Remote Backend  

Edit backend.tf:

```hcl
terraform {
  backend "s3" {
    bucket         = "<YOUR_BUCKET>"
    key            = "lesson-8-9/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
```

Then migrate state:

```hcl
terraform init -reconfigure
```

---

### 4. Configure kubectl access to EKS

```bash
aws eks update-kubeconfig \
  --region us-east-1 \
  --name <EKS_CLUSTER_NAME>
```

Verify:

```bash
kubectl get nodes
```

---

### Jenkins (CI)   
Access Jenkins UI

```bash
kubectl -n jenkins get svc
```

Open the EXTERNAL-IP in browser.

Get admin password:

```bash
kubectl -n jenkins get secret jenkins \
  -o jsonpath="{.data.jenkins-admin-password}" | base64 -d
```

---

### Jenkins Credentials

Create the following credentials in Jenkins UI:

1. GitHub credentials
- Type: Username & Password
- ID: github-token
- Username: GitHub username
- Password: GitHub Personal Access Token

2. AWS credentials
- Type: Username & Password
- ID: aws-credentials
- Username: AWS_ACCESS_KEY_ID
- Password: AWS_SECRET_ACCESS_KEY

---

### Jenkins Pipeline Verification
1. Create a Pipeline job
2. Choose Pipeline script from SCM
3. Point to Repo 1
4. Script path: Jenkinsfile
5. Click Build Now

What Jenkins does:
- Builds Docker image from Dockerfile
- Pushes image to ECR
- Updates values.yaml in Repo 2
- Pushes commit to master

---

### Argo CD (CD)  
Access Argo CD UI

```bash
kubectl -n argocd get svc argocd-server
```

Get admin password:  

```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d
```

Login:
- Username: admin
- Password: value from command above

---

### Verify Deployment in Argo CD

In Argo CD UI:
- Application status: Synced
- Health status: Healthy

Argo CD automatically deploys when:
- Jenkins updates Helm chart in Repo 2
- Git changes are detected

--- 

### Database Secrets Management

Secrets are NOT stored in Git.

Create Kubernetes Secret manually:

```bash
kubectl -n default create secret generic django-db \
  --from-literal=DB_PASSWORD='yourpassword'
```

The Helm chart references this secret using existingSecretName.

---

### Cleanup (IMPORTANT)

To avoid AWS charges:

```bash
terraform destroy
```

Optional cleanup:

```bash
kubectl -n default delete secret django-db
```

Destroying S3/DynamoDB backend removes Terraform state.