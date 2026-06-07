# Project Bedrock — InnovateMart EKS Deployment

**Student:** Vivian Nzekwe  
**Student ID:** ALT/SOE/025/4699  
**Track:** Cloud Engineering — AltSchool Africa (Karatu 2025, Semester 3)

---

## Overview

This project provisions a production-grade Kubernetes environment on AWS for 
InnovateMart, a growing e-commerce startup. The infrastructure is fully 
automated using Terraform and deployed via a GitHub Actions CI/CD pipeline.

The retail store application runs on Amazon EKS with managed AWS services 
replacing all in-cluster databases — a deliberate architectural decision to 
improve reliability, scalability, and separation of concerns.

---

## What I Built

### Infrastructure (Terraform)
- A custom VPC (`project-bedrock-vpc`) with public and private subnets 
  across two Availability Zones in `us-east-1`
- An EKS cluster (`project-bedrock-cluster`) running Kubernetes v1.32 
  with 2× t3.medium managed nodes
- Remote Terraform state stored in S3 with versioning enabled
- All resources tagged `Project: karatu-2025-capstone`

### Application
- Deployed the AWS Retail Store Sample App to the `retail-app` namespace
- 10 pods running: ui, catalog, orders, carts, checkout, redis, 
  rabbitmq, and supporting services
- Exposed via an Application Load Balancer using the AWS Load Balancer 
  Controller and a Kubernetes Ingress resource

### Data Layer
Instead of running databases inside the cluster (the default), I replaced 
them with managed AWS services:

| Service | Purpose |
|---|---|
| RDS MySQL (db.t3.micro) | Catalog service database |
| RDS PostgreSQL (db.t3.micro) | Orders service database |
| DynamoDB (bedrock-carts) | Shopping cart storage |

Both RDS instances run in private subnets with security groups that only 
allow inbound traffic from EKS nodes. Database credentials are stored in 
AWS Secrets Manager (`bedrock/db-credentials`) and never hardcoded.

### Security
- IAM user `bedrock-dev-view` created with `ReadOnlyAccess` for console
- Kubernetes RBAC configured — user mapped to the built-in `view` 
  ClusterRole, allowing `kubectl get pods` but blocking `kubectl delete`
- S3 PutObject permission granted only to the assets bucket
- All secrets managed via AWS Secrets Manager

### Observability
- EKS control plane logging enabled (API, Audit, Authenticator, 
  ControllerManager, Scheduler) — visible in CloudWatch
- Amazon CloudWatch Observability EKS Add-on installed for container logs

### Serverless Extension
- Private S3 bucket (`bedrock-assets-4699`) for product image uploads
- Lambda function (`bedrock-asset-processor`, Python 3.12) triggered on 
  every S3 upload, logs filename to CloudWatch:
  `Image received: [filename]`

### CI/CD Pipeline (GitHub Actions)
- **Pull Request** → runs `terraform plan`, posts output as PR comment
- **Merge to main with `[apply]`** → runs `terraform apply`
- AWS credentials stored as GitHub repository secrets — never hardcoded
- Lambda function packaged automatically during the pipeline run

---

## Repository Structure

project-bedrock/
├── terraform/
│   ├── main.tf          # AWS provider + default tags
│   ├── backend.tf       # S3 remote state configuration
│   ├── variables.tf     # Input variables
│   ├── outputs.tf       # Required grading outputs
│   ├── vpc.tf           # VPC, subnets, NAT gateway
│   ├── eks.tf           # EKS cluster + node group
│   ├── rds.tf           # RDS MySQL, PostgreSQL, Secrets Manager
│   ├── dynamodb.tf      # DynamoDB carts table
│   ├── s3.tf            # Assets S3 bucket
│   ├── lambda.tf        # Lambda function + S3 trigger
│   └── iam.tf           # Developer IAM user + Lambda role
├── k8s/
│   ├── namespace.yaml   # retail-app namespace
│   ├── ingress.yaml     # ALB ingress resource
│   └── rbac-dev.yaml    # Developer RBAC binding
├── lambda/
│   └── handler.py       # Asset processor function
├── .github/workflows/
│   └── terraform.yml    # CI/CD pipeline
├── grading.json         # Terraform outputs for grading script
└── README.md

---

## How to Deploy

### Prerequisites
- AWS CLI configured with appropriate permissions
- Terraform >= 1.10.0
- kubectl, helm, eksctl installed

### 1. Trigger via CI/CD (recommended)
```bash
git commit -m "deploy: your message here [apply]"
git push origin main
```
The pipeline will run `terraform apply` automatically.

### 2. Deploy manually
```bash
cd terraform
terraform init
terraform apply -var="student_id=4699" -var="db_password=YOUR_PASSWORD"
```

### 3. Connect kubectl to the cluster
```bash
aws eks update-kubeconfig --region us-east-1 --name project-bedrock-cluster
```

### 4. Deploy the application
```bash
kubectl create namespace retail-app
kubectl apply -f https://github.com/aws-containers/retail-store-sample-app/releases/latest/download/kubernetes.yaml -n retail-app
kubectl apply -f k8s/ingress.yaml
kubectl apply -f k8s/rbac-dev.yaml
```

### 5. Install AWS Load Balancer Controller
```bash
helm repo add eks https://aws.github.io/eks-charts
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=project-bedrock-cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller
```

### 6. Get the application URL
```bash
kubectl get ingress -n retail-app
```

---

## Tear Down
```bash
cd terraform
terraform destroy -var="student_id=4699" -var="db_password=YOUR_PASSWORD"
```
> Note: Delete the ALB and empty the S3 bucket before running destroy 
> to avoid dependency errors.

---

## Key Design Decisions

**Why replace in-cluster databases with managed services?**  
Running MySQL and PostgreSQL as pods means losing data if a pod crashes. 
RDS provides automated backups, multi-AZ failover, and removes database 
management from the application team entirely.

**Why a single NAT Gateway?**  
Cost optimisation for this assessment. In production, each AZ would have 
its own NAT Gateway for high availability.

**Why store secrets in Secrets Manager instead of Kubernetes secrets?**  
Kubernetes secrets are base64 encoded, not encrypted by default. 
Secrets Manager provides encryption at rest, automatic rotation, and 
fine-grained IAM access control.