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

---

# Additional Deployment Steps and Corrections

The following checks make this a safer, repeatable fresh-deployment runbook. Always compare commands and resource names with the current Terraform and Kubernetes files before running them.

## 1. Prepare and publish the GitHub repository

From the project root:

```
cd ~/Music/taskpulse
git status
git remote -v
```

Create or review `.gitignore` before committing. At minimum, exclude:

```
**/.terraform/*
*.tfstate
*.tfstate.*
*.tfplan
terraform.tfvars
*.auto.tfvars
.env
.env.*
!.env.example
*.pem
*.key
__pycache__/
*.py[cod]
.venv/
venv/
node_modules/
dist/
.DS_Store
```

Never commit AWS credentials, database passwords, Cognito client secrets, real Kubernetes Secrets, Terraform state or private keys.

If this is not already a Git repository:

```
git init
git add .
git status
git commit -m "Initial TaskPulse project"
git branch -M main
git remote add origin YOUR_GITHUB_REPOSITORY_URL
git push -u origin main
```

If a remote already exists, do not add it again. Verify the remote and branch first.

## 2. Verify AWS account and existing resources

```
export AWS_REGION=ap-south-1
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

printf 'Account: %s\nRegion: %s\n' "$AWS_ACCOUNT_ID" "$AWS_REGION"
```

Confirm the account is the intended account before proceeding. Inspect for resources left behind by a partial teardown:

```
aws eks list-clusters --region "$AWS_REGION"
aws rds describe-db-instances --region "$AWS_REGION"
aws ecr describe-repositories --region "$AWS_REGION"
aws elbv2 describe-load-balancers --region "$AWS_REGION"
aws ec2 describe-nat-gateways --region "$AWS_REGION"
```

## 3. Configure Terraform state, variables and workspace

Read the backend configuration first:

```
cd terraform-infra
cat backend.tf
```

The S3 backend bucket and key configured in `backend.tf` must exist and be accessible before `terraform init`. If the old bucket was deleted, recreate and configure the backend deliberately. Do not delete a state bucket while it is still needed to manage infrastructure.

Review the variables:

```
grep -RInE 'variable |default[[:space:]]*=' --include='*.tf' .
cat learning.tfvars.example
```

Create and edit a local variable file only after confirming its required values:

```
cp learning.tfvars.example terraform.tfvars
```

Keep `terraform.tfvars` out of Git. If the configuration uses workspaces, inspect and select the intended one:

```
terraform workspace list
terraform workspace select dev
```

Only select `dev` if it exists and is the intended environment. If the project intentionally uses workspaces and `dev` does not exist, create it only after confirming the backend and environment design:

```
terraform workspace new dev
```

Initialize and validate:

```
terraform init
terraform fmt -recursive
terraform validate
terraform plan -var-file=terraform.tfvars
```

Review the entire plan, especially resource replacements and deletions, before applying:

```
terraform apply -var-file=terraform.tfvars
```

If the current Terraform configuration uses a different variable-file convention, follow that configuration instead. Record outputs, but do not publish sensitive values:

```
terraform output
cd ..
```

## 4. Verify EKS and Pod Identity

Use the actual cluster name from the current Terraform configuration:

```
aws eks update-kubeconfig \
  --region "$AWS_REGION" \
  --name taskpulse-cluster

kubectl cluster-info
kubectl get nodes -o wide
kubectl get pods -n kube-system
```

Check the Pod Identity Agent:

```
aws eks describe-addon \
  --cluster-name taskpulse-cluster \
  --addon-name eks-pod-identity-agent \
  --region "$AWS_REGION"
```

If Terraform already manages this add-on, do not install a duplicate. Confirm the backend service account and its association:

```
kubectl get serviceaccount taskpulse-backend
grep -n -A8 -B4 'serviceAccountName' k8s/backend.yaml

aws eks list-pod-identity-associations \
  --cluster-name taskpulse-cluster \
  --region "$AWS_REGION"
```

The association must use the intended namespace, service account and IAM role. The role must have only the permissions the backend needs, including the correct RDS IAM database-connect permission.

## 5. Ensure ECR image tags match the manifests

Check the image references in Kubernetes YAML:

```
grep -RIn 'image:' k8s/
```

Get the current AWS account ID dynamically and authenticate:

```
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=ap-south-1

aws ecr get-login-password --region "$AWS_REGION" \
  | docker login \
      --username AWS \
      --password-stdin \
      "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"
```

Build, tag and push both images using the exact tags referenced by the manifests. For example, if the manifest references `v3`, push `v3`; do not push `v2` and expect a manifest referencing `v3` to use it.

```
docker build --platform linux/amd64 -t taskpulse-backend:v3 ./backend
docker tag taskpulse-backend:v3 \
  "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/taskpulse-backend:v3"
docker push \
  "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/taskpulse-backend:v3"

docker build --platform linux/amd64 -t taskpulse-frontend:v3 ./frontend
docker tag taskpulse-frontend:v3 \
  "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/taskpulse-frontend:v3"
docker push \
  "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/taskpulse-frontend:v3"
```

Change `v3` consistently if you choose another release tag. The previous ECR repositories used immutable tags, so do not attempt to overwrite an existing tag. Verify pushed images:

```
aws ecr describe-images --repository-name taskpulse-backend --region "$AWS_REGION"
aws ecr describe-images --repository-name taskpulse-frontend --region "$AWS_REGION"
```

## 6. Verify database connectivity before migration

Before running the migration job, verify:

- RDS is `available` and its endpoint matches the current Terraform output.
- RDS is private and its security group allows TCP 5432 only from the intended workload security group or other deliberately configured source.
- The backend and migration pods can reach RDS.
- The database name and username match the application configuration.
- The backend IAM role has the required `rds-db:connect` permission for the application database user.
- The RDS CA bundle is available to the backend image and TLS hostname verification is configured correctly.
- The administrator secret exists in Secrets Manager and the deployment identity can retrieve it.

Do not open PostgreSQL to `0.0.0.0/0`.

Inspect the repository ConfigMap and migration manifests before applying:

```
cat k8s/db-connection.yaml
cat k8s/db-migration.yaml
```

Apply the ConfigMap if its keys and values match the current configuration:

```
kubectl apply -f k8s/db-connection.yaml
```

The Secret creation command in the main guide requires `jq`. Install it first. Retrieve credentials without printing them, create the Kubernetes Secret from standard input, and verify only its metadata:

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

kubectl get secret db-admin-credentials
```

Inspect the migration manifest to confirm the Secret name, image tag, database configuration and service account. Run the migration only after database connectivity and credentials are ready. Verify the job completed successfully and inspect its logs.

## 7. Make Load Balancer Controller setup idempotent

Before creating IAM resources, check whether they already exist:

```
aws iam get-role \
  --role-name taskpulse-aws-load-balancer-controller

kubectl get serviceaccount aws-load-balancer-controller -n kube-system

aws eks list-pod-identity-associations \
  --cluster-name taskpulse-cluster \
  --region "$AWS_REGION"
```

If the role, policy, service account or association already exists, inspect and reuse or update it instead of blindly creating duplicates. Use the official controller IAM policy that matches the controller version being installed. Review the policy before attaching it.

Confirm that the controller's Pod Identity role trust policy allows the EKS Pod Identity service to assume the role, and that the association points to namespace `kube-system` and service account `aws-load-balancer-controller`.

The Helm chart version and controller application version are different version numbers. Verify compatibility before installing or upgrading. Also verify the VPC ID and public subnet tags required for an internet-facing ALB.

## 8. Verify Cognito and ACM before applying ingress

Inspect `k8s/taskpulse-ingress-production.yaml` and confirm all values belong to the current deployment:

- ACM certificate ARN and status.
- Certificate region (`ap-south-1`) and domain name.
- Cognito user pool ARN.
- Cognito app client ID and client configuration.
- Cognito domain.
- Ingress hostname and ALB annotations.
- Callback URL: `https://taskpulse.smokebyte.space/oauth2/idpresponse`.
- Logout URL: `https://taskpulse.smokebyte.space/`.

Do not reuse historical resource IDs without checking that those resources still exist. Never commit the Cognito client secret or user password.

## 9. Verify ALB targets and DNS

After applying the ingress:

```
kubectl get ingress
kubectl describe ingress taskpulse
```

Wait for ingress reconciliation and ALB provisioning. Check the ALB target group health in AWS before changing DNS.

Create or update the GoDaddy CNAME record only after obtaining the current ALB DNS name. The ALB hostname can change after recreation; do not reuse an old value.

```
dig +short taskpulse.smokebyte.space
curl -I https://taskpulse.smokebyte.space
```

An unauthenticated redirect to Cognito is expected when ALB authentication is enabled. It does not, by itself, prove that the backend or database works.

## 10. Complete end-to-end tests

After Cognito login:

1. Confirm the frontend loads without browser console errors.
2. Create a task.
3. Retrieve the task list.
4. Update a task status.
5. Refresh and confirm the change persists.
6. Check backend logs for successful API requests.
7. Check the backend readiness endpoint.
8. Confirm ALB targets remain healthy.
9. Confirm pods have no unexpected restarts.
10. Verify database persistence using an approved database access method.

Useful checks:

```
kubectl get pods -A -o wide
kubectl get deployments
kubectl get services
kubectl get ingress
kubectl get jobs
kubectl get pdb

kubectl logs deployment/taskpulse-backend --tail=100
kubectl logs deployment/taskpulse-frontend --tail=100
```

## 11. Safer teardown and post-destroy checks

**Important:** the previous RDS configuration had deletion protection disabled and `skip_final_snapshot=true`. Destroying that database with those settings can permanently delete its data without a final snapshot. Back up anything you need before teardown.

Use this order:

1. Back up the database if its data must be retained.
2. Delete the Kubernetes Ingress.
3. Wait for the ALB and its target groups to be deleted.
4. Remove application workloads and Kubernetes resources.
5. Remove separately created Pod Identity associations and IAM resources only if they are not managed by Terraform.
6. Review the destroy plan for the correct Terraform workspace.
7. Run Terraform destroy.
8. Verify EKS, EC2 nodes, NAT Gateways, Elastic IPs, RDS and ALBs are removed.
9. Check separately managed ECR images/repositories, IAM roles and policies, Cognito resources, ACM certificates, Secrets Manager secrets, CloudWatch log groups and security groups.
10. Preserve the Terraform state backend until the environment is confirmed destroyed and no other environment depends on it.

From `terraform-infra`, after selecting the correct workspace:

```
terraform workspace show
terraform plan -destroy -var-file=terraform.tfvars
```

Review the plan. Only after confirming the target environment:

```
terraform destroy -var-file=terraform.tfvars
```

Do not use broad account-wide deletion commands. Do not delete shared IAM resources, state buckets, certificates or ECR repositories unless you have confirmed they belong exclusively to this project and are no longer needed.

## 12. Final deployment checklist

- \[ \] Correct AWS account and `ap-south-1` region confirmed.
- \[ \] Git repository reviewed; secrets and Terraform state excluded.
- \[ \] Terraform backend exists and state is accessible.
- \[ \] Correct Terraform workspace and variables selected.
- \[ \] Terraform plan reviewed before apply.
- \[ \] VPC, subnets, EKS, node group, RDS, ECR and Cognito ready.
- \[ \] kubectl connects to the intended cluster.
- \[ \] EKS Pod Identity Agent is ready.
- \[ \] Backend IAM role and association verified.
- \[ \] Frontend and backend images pushed with matching immutable tags.
- \[ \] RDS security group and database connectivity verified.
- \[ \] Kubernetes database ConfigMap and credentials Secret created.
- \[ \] Database migration job completed successfully.
- \[ \] Load Balancer Controller IAM role and association verified.
- \[ \] Load Balancer Controller is ready.
- \[ \] Frontend and backend deployments are healthy.
- \[ \] Availability policy applied.
- \[ \] Cognito configuration and callback URL verified.
- \[ \] ACM certificate is issued in the correct region.
- \[ \] Ingress reconciled and ALB targets healthy.
- \[ \] GoDaddy CNAME points to the current ALB DNS name.
- \[ \] HTTPS and Cognito login tested.
- \[ \] Create, list and update task operations tested.
- \[ \] Database persistence verified.
- \[ \] Costs and teardown plan reviewed.
