# Final DevOps Project — AWS Infrastructure with Terraform, EKS & Full CI/CD

## Overview

This repository contains the **final DevOps project**, demonstrating a **full production-style CI/CD and GitOps workflow** on **AWS**, fully automated with **Terraform** and **Kubernetes**.

### Key principles:

* Infrastructure as Code (**Terraform**)
* Container orchestration (**Amazon EKS**)
* CI/CD automation (**Jenkins + Argo CD**)
* GitOps deployment model
* Secure secrets management (no secrets in Git)
* Monitoring & autoscaling (**Prometheus + Grafana + HPA**)

---

## Technologies Used

* **Terraform** — AWS Infrastructure as Code
* **AWS VPC** — Networking and security isolation
* **Amazon EKS** — Kubernetes cluster
* **Amazon ECR** — Docker image registry
* **Amazon RDS / Aurora** — Managed PostgreSQL database
* **Jenkins** — Continuous Integration (CI)
* **Argo CD** — GitOps Continuous Deployment (CD)
* **Helm** — Kubernetes package manager
* **Prometheus** — Metrics collection
* **Grafana** — Monitoring dashboards
* **Django** — Example application

---

## High-Level CI/CD Architecture

```
Developer
    |
    | git push (application code)
    v
GitHub (Repo 1: Infrastructure + App)
    |
    | Jenkinsfile
    v
Jenkins (Kubernetes Agent)
    |
    | • Build Docker image
    | • Push image to Amazon ECR
    | • Update Helm values.yaml
    v
GitHub (Repo 2: Helm Charts – GitOps)
    |
    | GitOps sync
    v
Argo CD
    |
    | Auto-deploy
    v
Amazon EKS (Kubernetes)
```

---

## Repositories

### Repository 1 — Infrastructure & Application

[Repo link](https://github.com/RadislavKrasnov/goit-devops-hw/tree/final-project)  

Contains:

* Terraform root and modules
* Jenkinsfile
* Dockerfile
* Django application source code

Used for **CI and Infrastructure management**

---

### Repository 2 — Helm Charts (GitOps)

[Repo link](https://github.com/RadislavKrasnov/goit-devops-charts/tree/master)

Contains:

* Helm chart for Django application only
* Watched by Argo CD

Used for **CD only**

> **Important:** Dockerfile and source code are **NOT stored** in the Helm repository.

---

## Project Structure  

```
Project/
│
├── main.tf
├── backend.tf
├── providers.tf
├── variables.tf
├── outputs.tf
│
├── modules/
│  ├── s3-backend/
│  ├── vpc/
│  ├── ecr/
│  ├── eks/
│  ├── rds/
│  ├── jenkins/
│  ├── argo_cd/
│  └── monitoring/
│
├── charts/
│  └── django-app/
│     ├── templates/
│     │  ├── deployment.yaml
│     │  ├── service.yaml
│     │  ├── configmap.yaml
│     │  └── hpa.yaml
│     ├── Chart.yaml
│     └── values.yaml
│
└── app/  
├── Dockerfile  
├── Jenkinsfile  
```

---

## Prerequisites

* Terraform `>= 1.4`
* AWS account
* AWS CLI (`aws configure`)
* kubectl
* Helm
* Docker (optional, for local builds)
* IAM user with access to:

  * VPC
  * EC2
  * EKS
  * ECR
  * RDS
  * S3
  * DynamoDB
  * IAM

---

## Infrastructure Deployment (Terraform)

### 1 Configure AWS

```bash
aws configure
aws sts get-caller-identity
```

---

### 2 Terraform Backend Bootstrap

Because Terraform state is stored in **S3 + DynamoDB**, backend resources must exist first.

```bash
terraform init  
terraform apply  
terraform init -reconfigure
```

---

### 3 Deploy Full Infrastructure

```bash
terraform apply
```

This creates:

* VPC with public & private subnets
* NAT Gateway
* EKS cluster
* ECR repository
* RDS or Aurora database
* Jenkins (Helm)
* Argo CD + Applications (Helm)
* Prometheus + Grafana (Helm)

---

### 4 Configure kubectl

```bash
aws eks update-kubeconfig \
  --region us-east-1 \
  --name lesson-7-eks

kubectl get nodes
```

---

## Verification  

### Namespaces  

```bash
kubectl get all -n jenkins
kubectl get all -n argocd
kubectl get all -n monitoring
```

---

## Access Services (Port-Forward)  

### Jenkins  

```bash
kubectl port-forward svc/jenkins 8080:8080 -n jenkins
```

Get admin password:

```bash
kubectl get secret -n jenkins jenkins \
  -o jsonpath="{.data.jenkins-admin-password}" | base64 -d
```

---

### Argo CD  

```bash
kubectl port-forward svc/argocd-server 8081:443 -n argocd
```

Get admin password:

```bash
kubectl get secret -n argocd argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d
```

---

### Grafana  

```bash
kubectl port-forward svc/kube-prom-stack-grafana 3000:80 -n monitoring
```

Get Grafana password:

```bash
kubectl get secret -n monitoring kube-prom-stack-grafana \
  -o jsonpath="{.data.admin-password}" | base64 -d
```

---

## CI/CD Pipeline (Jenkins - ECR - Argo CD)  

### Jenkins Credentials  

Create in Jenkins UI:  

1 **GitHub**  

* ID: `github-token`
* Type: Username & Password
* Password = GitHub PAT

2 **AWS**  

* ID: `aws-credentials`
* Username = AWS_ACCESS_KEY_ID
* Password = AWS_SECRET_ACCESS_KEY

---

### Pipeline Flow  

1. Jenkins builds Docker image
2. Pushes image to ECR
3. Updates Helm `values.yaml`
4. Pushes change to Helm repo
5. Argo CD auto-syncs and deploys

---

## Database Secrets Management  

**Secrets are NOT stored in Git**  

Create Kubernetes Secret manually:  

```bash
kubectl -n default create secret generic django-db \
  --from-literal=DB_PASSWORD='yourpassword'
```

Application reads the value using `envFrom` / `secretRef`.

---

## Monitoring & Autoscaling

* **Prometheus** — metrics collection
* **Grafana** — dashboards
* **HPA** — autoscaling based on CPU

Verify metrics inside Grafana dashboards.

---

## Flexible Terraform RDS / Aurora Module

The project includes a **universal Terraform DB module** supporting:

* Standard **Amazon RDS**
* **Amazon Aurora** cluster

Switching is controlled by:

```hcl
use_aurora = true | false
```

Both modes automatically create:

* DB Subnet Group
* Security Group
* Parameter Group

Outputs remain consistent across modes.

[Details about Terraform RDS / Aurora Module configuration read here](./DB-CONFIG.md)  

---

## Cleanup (IMPORTANT)

```bash
terraform destroy
```

Optional:

```bash
kubectl delete secret django-db -n default
```

Destroying backend removes Terraform state (S3 + DynamoDB).

---
