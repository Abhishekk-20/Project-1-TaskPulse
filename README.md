# TaskPulse --- Production-Style 3-Tier Application on AWS EKS

A containerized task-management application deployed on Amazon EKS, with a React frontend, Flask backend, PostgreSQL database, Cognito authentication, and an AWS Application Load Balancer.

## Project Overview

TaskPulse is a three-tier task-management application designed to demonstrate how a modern containerized application can be deployed and operated on AWS.

The application separates the presentation, application logic, and database layers.

---

**Layer**   **Technology**           **Responsibility**

---

Frontend    React, Vite, Nginx       User interface and API requests

Backend     Python, Flask, Gunicorn  Application APIs and business logic

## Database    Amazon RDS PostgreSQL    Persistent application data

The application runs on Amazon EKS. Container images are stored in Amazon ECR. Amazon Cognito provides user authentication, and an Application Load Balancer provides external HTTPS access.

### 

### Project objectives

Build and containerize a full-stack application.

Provision AWS infrastructure using Terraform.

Deploy containers to Kubernetes on Amazon EKS.

Store container images in Amazon ECR.

Connect Kubernetes workloads securely to PostgreSQL.

Configure authentication using Amazon Cognito.

Expose the application through an HTTPS Application Load Balancer.

Implement health checks, resource limits and Kubernetes availability controls.

Practice infrastructure deployment, troubleshooting, security and teardown.


-- Diagram 

---<img width="1672" height="941" alt="image" src="https://github.com/user-attachments/assets/f89df5dd-522a-48ac-9923-390f38a2f8e2" />


---

---


Architecture

The application uses the following request flow:

```
                         Internet
                            |
                            |
                  taskpulse.smokebyte.space
                            |
                     GoDaddy DNS
                            |
                            v
                AWS Application Load Balancer
                       HTTPS :443
                            |
                  Cognito Authentication
                            |
                            v
                    Frontend Service
                            |
                     Frontend Pods
                       React / Nginx
                            |
                     /api requests
                            |
                            v
                     Backend Service
                            |
                     Backend Pods
                     Flask / Gunicorn
                            |
                   PostgreSQL connection
                            |
                            v
                    Amazon RDS PostgreSQL
                     Private subnets











```

## Technology Stack

**Category**             **Tools and services**

---

Frontend                 React 18, Vite, Nginx Backend                  Python, Flask, Gunicorn Database                 Amazon RDS, PostgreSQL 15 Containers               Docker Container registry       Amazon ECR Orchestration            Kubernetes, Amazon EKS Infrastructure as Code   Terraform Authentication           Amazon Cognito Load balancing           AWS Application Load Balancer TLS                      AWS Certificate Manager Workload permissions     EKS Pod Identity, IAM DNS                      GoDaddy DNS Monitoring and logs      Amazon CloudWatch, Kubernetes logs Operating environment    Linux

## Repository Structure

```
taskpulse/
│
├── backend/
│   ├── app.py
│   ├── Dockerfile
│   ├── migrate.py
│   ├── requirements.txt
│   └── migrations/
│       └── 001_create_items.sql
│
├── frontend/
│   ├── Dockerfile
│   ├── index.html
│   ├── nginx.conf
│   ├── package.json
│   ├── package-lock.json
│   └── src/
│       ├── App.jsx
│       ├── index.css
│       └── main.jsx
│
├── terraform-infra/
│   ├── backend.tf
│   ├── budget.tf
│   ├── cloudwatch.tf
│   ├── cognito.tf
│   ├── ecr.tf
│   ├── eks.tf
│   ├── learning.tfvars.example
│   ├── output.tf
│   ├── rds.tf
│   ├── versions.tf
│   └── vpc.tf
│
├── k8s/
│   ├── availability.yaml
│   ├── backend.yaml
│   ├── db-connection.yaml
│   ├── db-migration.yaml
│   ├── frontend.yaml
│   ├── taskpulse-ingress.yaml
│   └── taskpulse-ingress-production.yaml
│
├── iam/
│   ├── iam_policy.json
│   └── pod-identity-trust-policy.json
│
├── docs/
│   └── architecture.md
│
├── docker-compose.yml
├── infra.webp
├── siteimage.png
├
└── README.md
```

## 5. Application Features

### Frontend

React-based task-management interface.

Built using Vite.

Served through Nginx.

Communicates with the backend through `/api/`.

Runs as a non-root container.

Uses a writable temporary volume for Nginx runtime files.

### Backend

Flask REST API.

Gunicorn application server.

PostgreSQL database integration.

IAM database authentication support.

TLS verification for database connections.

Health and readiness endpoints.

Important API endpoints:

**Endpoint**                   **Purpose**

---

`/livez`                       Liveness check `/readyz`                      Readiness check `/health`                      Application health `/api/items`                   Retrieve task items `POST /api/items`              Create an item `PUT /api/items/<id>/status`   Update item status

### Database

PostgreSQL hosted on Amazon RDS.

Private network access.

Application database: `taskpulse`.

Database schema initialized through a Kubernetes migration job.

Application database authentication configured for IAM where supported by the deployment configuration.

## Prerequisites

Before deploying, install and configure:

AWS CLI

Terraform

Docker

kubectl

eksctl

Helm

Git

Verify the tools:

```
aws --version
terraform version
docker --version
kubectl version --client
eksctl version
helm version
git --version
```

Configure AWS credentials:

```
aws configure
```

Verify the AWS identity and region:

```
aws sts get-caller-identity
aws configure get region
```

The expected deployment region is:

```
ap-south-1




Deployment Order
```

Deploy the application in this order. Do not skip infrastructure or identity setup.

---

**Phase**   **Task**

---

1           Verify AWS account, tools and Terraform configuration

2           Configure Terraform backend and variables

3           Provision VPC, subnets, EKS, RDS, ECR and Cognito

4           Configure kubectl and verify the EKS cluster

5           Configure EKS Pod Identity and IAM permissions

6           Build frontend and backend Docker images

7           Push images to Amazon ECR

8           Configure database connection and run migrations

9           Install AWS Load Balancer Controller

10          Deploy backend and frontend Kubernetes resources

11          Configure ingress, ACM certificate and Cognito authentication

12          Configure GoDaddy DNS

## 13          Verify the application end to end

### Step 1 --- Clone the repository

```
git clone YOUR_GITHUB_REPOSITORY_URL
cd taskpulse
```

Replace the URL with the actual repository URL after pushing this project to GitHub.

### Step 2 --- Configure Terraform

```
cd terraform-infra
terraform init
```

Inspect the supplied example variables before creating your own configuration:

```
cat learning.tfvars.example
```

Configure the required values using the variables defined in the Terraform files. Do not copy example settings blindly into a production deployment.

Validate and review:

```
terraform fmt -recursive
terraform validate
terraform plan
```

Review the plan carefully before applying it.

### Provision AWS infrastructure

```
terraform apply
```

Confirm the proposed changes before proceeding.

Record the Terraform outputs:

```
terraform output
```

Keep sensitive outputs private. Do not commit Terraform state, secret values or generated credentials to GitHub.

### Build and push container images

### Authenticate Docker with ECR

Set the AWS account ID and region:

```
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=ap-south-1
```

Authenticate:

```
aws ecr get-login-password --region "$AWS_REGION" \
  | docker login \
    --username AWS \
    --password-stdin \
    "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"
```

### 9.2 Build Backend Image

```
docker build --platform linux/amd64 \
  -t taskpulse-backend:v2 ./backend
```

Tag the image:

```
docker tag taskpulse-backend:v2 \
  "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/taskpulse-backend:v2"
```

Push the image:

```
docker push \
  "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/taskpulse-backend:v2"
```

### 9.3 Build Frontend Image

```
docker build --platform linux/amd64 \
  -t taskpulse-frontend:v2 ./frontend
```

Tag the image:

```
docker tag taskpulse-frontend:v2 \
  "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/taskpulse-frontend:v2"
```

Push the image:

```
docker push \
  "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/taskpulse-frontend:v2"
```

Verify repository images:

```
aws ecr describe-images \
  --repository-name taskpulse-backend \
  --region ap-south-1
aws ecr describe-images \
  --repository-name taskpulse-frontend \
  --region ap-south-1




Configure Database Connectivity
```

The backend connects to PostgreSQL hosted on Amazon RDS.

Retrieve the RDS endpoint from Terraform outputs:

```
cd terraform-infra
terraform output
cd ..
```

Create the database ConfigMap using your actual RDS endpoint:

```
kubectl create configmap taskpulse-db \
  --from-literal=DB_HOST=YOUR_RDS_ENDPOINT \
  --from-literal=DB_NAME=taskpulse \
  --dry-run=client -o yaml | kubectl apply -f -
```

### Create Database Credentials Secret

The database administrator credentials are stored in AWS Secrets Manager.

Retrieve the secret ARN from Terraform:

```
cd terraform-infra
terraform output -raw secrets_manager_arn
cd ..
```

Create the Kubernetes Secret without displaying the password:

```
SECRET_ARN=$(cd terraform-infra && terraform output -raw secrets_manager_arn)

aws secretsmanager get-secret-value \
  --secret-id "$SECRET_ARN" \
  --query SecretString \
  --output text \
| jq -r '"DB_USER=\(.username)\nDB_PASSWORD=\(.password)"' \
| kubectl create secret generic db-admin-credentials \
    --from-env-file=/dev/stdin \
    --dry-run=client -o yaml \
| kubectl apply -f -
```

Verify only the Secret metadata:

```
kubectl get secret db-admin-credentials
```

Never print the secret values or commit them to source control.

## Configure EKS Pod Identity

The backend uses EKS Pod Identity to obtain AWS permissions for IAM database authentication.

Check the Pod Identity Agent:

```
aws eks describe-addon \
  --cluster-name taskpulse-cluster \
  --addon-name eks-pod-identity-agent \
  --region ap-south-1
```

Check the backend service account:

```
kubectl get serviceaccount taskpulse-backend
```

Verify the association:

```
aws eks list-pod-identity-associations \
  --cluster-name taskpulse-cluster \
  --region ap-south-1
```

The backend service account must be associated with the intended IAM role.

## Run Database Migration

The project uses a Kubernetes Job to initialize the PostgreSQL schema.

Apply the migration manifest:

```
kubectl apply -f k8s/db-migration.yaml
```

Check Job status:

```
kubectl get jobs
```

Check migration logs:

```
kubectl logs job/taskpulse-db-migrate-v2
```

Expected successful migration message:

```
Applied 001_create_items.sql
```

This migration creates the application database objects and application database role.

## Deploy Application to Kubernetes

### 13.1 Deploy Backend

Apply the backend manifest:

```
kubectl apply -f k8s/backend.yaml
```

Check backend pods:

```
kubectl get pods -l app=taskpulse-backend
```

Wait for rollout:

```
kubectl rollout status deployment/taskpulse-backend
```

Check backend logs:

```
kubectl logs deployment/taskpulse-backend --tail=50
```

### 13.2 Deploy Frontend

Apply the frontend manifest:

```
kubectl apply -f k8s/frontend.yaml
```

Check frontend pods:

```
kubectl get pods -l app=taskpulse-frontend
```

Wait for rollout:

```
kubectl rollout status deployment/taskpulse-frontend
```

### 13.3 Apply Availability Policies

```
kubectl apply -f k8s/availability.yaml
```

Check deployments:

```
kubectl get deployments
```

Check services:

```
kubectl get services
```

Expected application services:

`frontend-service`

`Backend-service`

## Install AWS Load Balancer Controller

The AWS Load Balancer Controller manages AWS Application Load Balancers through Kubernetes Ingress resources.

### 14.1 Create IAM Policy

Download the official AWS Load Balancer Controller IAM policy:

```
mkdir -p iam
cd iam

curl -fL \
  -o iam_policy.json \
  https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.14.1/docs/install/iam_policy.json
```

Validate JSON:

```
jq empty iam_policy.json
```

Create the IAM policy:

```
aws iam create-policy \
  --policy-name AWSLoadBalancerControllerIAMPolicy \
  --policy-document file://iam_policy.json
```

### 14.2 Create IAM Role

The controller requires an IAM role trusted by the EKS Pod Identity service.

Create the trust policy:

```
cat > pod-identity-trust-policy.json <<'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "pods.eks.amazonaws.com"
      },
      "Action": [
        "sts:AssumeRole",
        "sts:TagSession"
      ],
      "Condition": {
        "StringEquals": {
          "aws:SourceAccount": "YOUR_AWS_ACCOUNT_ID"
        },
        "ArnLike": {
          "aws:SourceArn": "arn:aws:eks:ap-south-1:YOUR_AWS_ACCOUNT_ID:cluster/taskpulse-cluster"
        }
      }
    }
  ]
}
EOF
```

Replace the account ID with your own AWS account ID.

Create the role and attach the controller policy:

```
aws iam create-role \
  --role-name taskpulse-aws-load-balancer-controller \
  --assume-role-policy-document file://pod-identity-trust-policy.json
aws iam attach-role-policy \
  --role-name taskpulse-aws-load-balancer-controller \
  --policy-arn arn:aws:iam::YOUR_AWS_ACCOUNT_ID:policy/AWSLoadBalancerControllerIAMPolicy
```

### 14.3 Create Service Account and Pod Identity Association

```
kubectl create serviceaccount aws-load-balancer-controller \
  --namespace kube-system
```

Create the association:

```
aws eks create-pod-identity-association \
  --cluster-name taskpulse-cluster \
  --namespace kube-system \
  --service-account aws-load-balancer-controller \
  --role-arn arn:aws:iam::YOUR_AWS_ACCOUNT_ID:role/taskpulse-aws-load-balancer-controller \
  --region ap-south-1
```

### 14.4 Install Using Helm

```
helm repo add eks https://aws.github.io/eks-charts
helm repo update eks
```

Install the controller:

```
helm install aws-load-balancer-controller \
  eks/aws-load-balancer-controller \
  --namespace kube-system \
  --version 1.14.0 \
  --set clusterName=taskpulse-cluster \
  --set region=ap-south-1 \
  --set vpcId=YOUR_VPC_ID \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller
```

Verify installation:

```
kubectl get deployment aws-load-balancer-controller -n kube-system
kubectl get pods -n kube-system | grep aws-load-balancer-controller



Configure HTTPS and Cognito Authentication
```

Amazon Cognito is used to authenticate users before they access the application through the ALB.

The Cognito integration requires:

User Pool ARN.

App Client ID.

App Client Secret.

Cognito domain.

Correct callback and logout URLs.

The ALB Cognito callback URL must be:

```
https://taskpulse.smokebyte.space/oauth2/idpresponse
```

The Cognito app client must have a generated client secret.

The Ingress manifest is:

```
k8s/taskpulse-ingress-production.yaml
```

Review the Cognito annotation and certificate ARN before applying it.

Apply Ingress:

```
kubectl apply -f k8s/taskpulse-ingress-production.yaml
```

Check Ingress:

```
kubectl get ingress
```

Wait for ALB provisioning:

```
kubectl describe ingress taskpulse
```

The ALB should have:

Internet-facing scheme.

HTTP listener on port 80.

HTTPS listener on port 443.

ACM certificate.

Cognito authentication.

Frontend target group.

## 16. Configure GoDaddy DNS

The application domain is:

```
taskpulse.smokebyte.space
```

After the ALB is created, retrieve its DNS name:

```
kubectl get ingress taskpulse
```

In GoDaddy DNS management, create a CNAME record:

**Field**   **Value**

---

Type        CNAME Name        taskpulse Value       YOUR\_ALB\_DNS\_NAME TTL         600 seconds

Do not change your domain nameservers for this configuration.

Verify DNS:

```
dig +short taskpulse.smokebyte.space
```

## 17. Validate the Application

### 17.1 Verify HTTPS

```
curl -I https://taskpulse.smokebyte.space
```

An unauthenticated request should redirect to the Cognito hosted login page.

### 17.2 Verify Frontend

Open:

[https://taskpulse.smokebyte.space](https://taskpulse.smokebyte.space)

Log in using a Cognito user account.

### 17.3 Verify Backend API

Use an authenticated browser session to test the application API.

Check backend health:

```
kubectl port-forward svc/backend-service 5000:5000
```

In another terminal:

```
curl http://localhost:5000/readyz
```

Expected response:

```
{
  "status": "ok"
}
```

### 17.4 Verify Kubernetes

```
kubectl get pods -o wide
kubectl get deployments
kubectl get services
kubectl get ingress
```

### 17.5 Verify Application Logs

```
kubectl logs deployment/taskpulse-frontend --tail=50
kubectl logs deployment/taskpulse-backend --tail=50
```

### 17.6 Verify Database Persistence

Create a task in the application, update its status, refresh the browser, and verify that the changes remain available.

This confirms the application can persist data through its backend and PostgreSQL database.

## Conclusion

TaskPulse demonstrates an end-to-end cloud-native deployment using AWS, Terraform, Docker, Kubernetes, and managed AWS services.

The project provides practical experience in building, deploying, securing, monitoring, troubleshooting, and cleaning up a multi-tier application in the cloud.

<img width="1366" height="669" alt="image" src="https://github.com/user-attachments/assets/59cdcb07-1a3f-4123-8e5e-ca074b465f65" />


**Live Application:** [https://taskpulse.smokebyte.space](https://taskpulse.smokebyte.space)

**AWS Region:** `ap-south-1`

