# TaskPulse

A production-style, three-tier task-management application deployed on Amazon EKS. TaskPulse uses a React frontend, Flask API, PostgreSQL database, Amazon Cognito authentication, and an AWS Application Load Balancer.

- **Live application:** [taskpulse.smokebyte.space](https://taskpulse.smokebyte.space)
- **AWS region:** `ap-south-1`

> **Cost and safety:** Deploying this project can create billable AWS resources. Review Terraform plans before applying, protect credentials and state, and follow the teardown guidance before removing infrastructure.

## Overview

TaskPulse demonstrates a cloud-native application lifecycle: build container images, provision AWS infrastructure with Terraform, deploy workloads to Kubernetes, authenticate users with Cognito, and connect privately to a managed PostgreSQL database.

| Layer | Technologies | Responsibility |
| --- | --- | --- |
| Frontend | React, Vite, Nginx | User interface and API requests |
| Backend | Python, Flask, Gunicorn | API and application logic |
| Database | Amazon RDS, PostgreSQL | Persistent application data |
| Platform | Docker, Amazon ECR, Amazon EKS, Kubernetes | Build, store, and run application containers |
| Infrastructure and access | Terraform, Cognito, AWS Load Balancer Controller, ALB | Provisioning, authentication, and ingress |

## Architecture

![TaskPulse AWS architecture](https://github.com/user-attachments/assets/f89df5dd-522a-48ac-9923-390f38a2f8e2)

Request flow:

```text
Internet
  -> taskpulse.smokebyte.space (GoDaddy DNS)
  -> AWS Application Load Balancer (HTTPS)
  -> Amazon Cognito authentication
  -> Frontend Service and React/Nginx pods
  -> /api requests to Backend Service and Flask/Gunicorn pods
  -> Amazon RDS PostgreSQL in private subnets
```

## Repository layout

```text
.
├── backend/                 Flask API, Dockerfile, and SQL migrations
├── frontend/                React app, Dockerfile, and Nginx configuration
├── terraform-infra/         Terraform configuration for AWS infrastructure
├── k8s/                     Kubernetes workloads, database jobs, and ingress
├── iam/                     IAM policy and Pod Identity trust policy
├── docs/                    Architecture documentation
├── docker-compose.yml       Local container orchestration
└── README.md
```

## Prerequisites

Install and configure the tools needed for your chosen deployment steps:

- Git
- AWS CLI and access to the intended AWS account
- Terraform
- Docker
- `kubectl`
- Helm
- `jq` (for the example Secrets Manager command)

`eksctl` may also be useful for EKS administration. Check installed tools and your AWS identity:

```bash
aws --version
terraform version
docker --version
kubectl version --client
helm version
aws sts get-caller-identity
aws configure get region
```

The example deployment uses `ap-south-1`. Confirm the account and region before creating resources.

## Local development

The repository includes a Docker Compose configuration. From the project root, inspect `docker-compose.yml` and follow its service configuration to start the local stack:

```bash
docker compose up --build
```

Stop the stack with `Ctrl+C`, then run:

```bash
docker compose down
```

## AWS deployment

The manifests and Terraform inputs contain deployment-specific names and values. Before applying anything, compare the commands below with the current files in `terraform-infra/`, `k8s/`, and `iam/`. Replace placeholders with values from your own deployment; do not reuse historical resource IDs or secrets.

### 1. Configure Terraform and review the plan

```bash
cd terraform-infra
cat backend.tf
cat learning.tfvars.example
terraform init
terraform fmt -recursive
terraform validate
```

Configure the required variables using the project’s Terraform definitions. Keep real values in an ignored local file, not in Git. Review the plan before applying:

```bash
terraform plan
terraform apply
terraform output
```

Use the variable-file convention required by the current configuration. Terraform state and outputs may contain sensitive data; do not publish them. Return to the repository root when done:

```bash
cd ..
```

### 2. Connect to EKS and verify the cluster

Use the actual cluster name from the Terraform configuration or outputs:

```bash
aws eks update-kubeconfig --region ap-south-1 --name taskpulse-cluster
kubectl cluster-info
kubectl get nodes -o wide
```

Verify the EKS Pod Identity Agent and the backend service-account association. If Terraform manages an add-on or association, inspect and reuse that configuration rather than creating a duplicate.

### 3. Build and push container images

Authenticate Docker to the ECR registry for the intended account and region:

```bash
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=ap-south-1

a ws ecr get-login-password --region "$AWS_REGION" \
  | docker login --username AWS --password-stdin \
    "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"
```

Build and push the frontend and backend images using the exact repository names and tags referenced in the Kubernetes manifests. For example, inspect them with:

```bash
grep -RIn 'image:' k8s/
```

Then build, tag, and push each image to the matching ECR repository. Do not overwrite an existing immutable image tag.

### 4. Configure database access and run migrations

Before migration, verify that RDS is available, the endpoint and database name are correct, and network access is restricted to the intended workloads. Do not expose PostgreSQL to `0.0.0.0/0`.

Inspect the database and migration manifests before applying them:

```bash
cat k8s/db-connection.yaml
cat k8s/db-migration.yaml
```

Apply the database configuration if its values match your environment. The database administrator credentials should be handled through the intended secret-management flow. Never print or commit secret values.

After confirming connectivity, credentials, image tag, and service account, run the migration job:

```bash
kubectl apply -f k8s/db-migration.yaml
kubectl get jobs
kubectl logs job/taskpulse-db-migrate-v2
```

Confirm the Job completed successfully before deploying the application.

### 5. Deploy the application

Apply the manifests after checking their image references, namespaces, service accounts, and configuration:

```bash
kubectl apply -f k8s/backend.yaml
kubectl rollout status deployment/taskpulse-backend

kubectl apply -f k8s/frontend.yaml
kubectl rollout status deployment/taskpulse-frontend

kubectl apply -f k8s/availability.yaml
```

Check pods, services, and recent application logs:

```bash
kubectl get pods -o wide
kubectl get deployments
kubectl get services
kubectl logs deployment/taskpulse-backend --tail=50
kubectl logs deployment/taskpulse-frontend --tail=50
```

### 6. Install the AWS Load Balancer Controller and configure ingress

Check whether the controller’s IAM policy, role, service account, and Pod Identity association already exist before creating them. Use the official IAM policy compatible with the controller version and the EKS cluster. The Helm chart version and controller application version are distinct; verify their compatibility.

Review the controller settings, including cluster name, region, VPC ID, service account, and subnet tags. Once the controller is ready, inspect `k8s/taskpulse-ingress-production.yaml` and verify the ACM certificate, Cognito settings, hostname, and ALB annotations before applying:

```bash
kubectl apply -f k8s/taskpulse-ingress-production.yaml
kubectl get ingress
kubectl describe ingress taskpulse
```

The Cognito callback URL configured for this example is:

```text
https://taskpulse.smokebyte.space/oauth2/idpresponse
```

Do not commit Cognito client secrets or user credentials.

### 7. Configure DNS and validate the deployment

Wait for the ALB to be provisioned and its targets to become healthy. Then create or update the GoDaddy CNAME for `taskpulse.smokebyte.space` to point to the **current** ALB DNS name. The ALB hostname can change if it is recreated.

```bash
dig +short taskpulse.smokebyte.space
curl -I https://taskpulse.smokebyte.space
```

An unauthenticated redirect to Cognito is expected when ALB authentication is enabled. It does not by itself confirm that the API or database is working.

## Validation

After signing in through Cognito:

1. Confirm the frontend loads without browser errors.
2. Create and update a task, then refresh to check persistence.
3. Check backend readiness and application logs.
4. Confirm Kubernetes pods are healthy and the ALB targets remain healthy.

Useful Kubernetes checks:

```bash
kubectl get pods -A -o wide
kubectl get deployments
kubectl get services
kubectl get ingress
kubectl get jobs
kubectl get pdb
kubectl logs deployment/taskpulse-backend --tail=100
kubectl logs deployment/taskpulse-frontend --tail=100
```

The backend defines `/livez`, `/readyz`, and `/health` checks. To test a service locally, confirm the service name and port in `k8s/backend.yaml`, then port-forward and request the relevant endpoint.

## Security and cost notes

- Never commit AWS credentials, database passwords, Cognito client secrets, private keys, real Kubernetes Secrets, Terraform state, or populated `terraform.tfvars` files.
- Keep RDS private and restrict database ingress to the intended workload security group.
- Grant IAM roles only the permissions required by their workloads.
- Review Terraform plans, especially resource replacements and deletions, before applying.
- AWS resources such as EKS, RDS, NAT Gateways, and load balancers can incur ongoing charges.

Ensure `.gitignore` excludes local state and secrets. At minimum, consider:

```gitignore
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

## Troubleshooting checklist

- **Pods are not starting:** inspect `kubectl describe pod <pod-name>` and the pod logs; check image names, tags, configuration, and resource limits.
- **Database connection fails:** verify the RDS endpoint, database configuration, security-group rules, credentials, TLS settings, and workload IAM permissions.
- **Migration fails:** inspect the Job status and logs; verify that the database is reachable and the migration image and secret references match the manifests.
- **Ingress or ALB is not ready:** inspect the Ingress events and controller logs; verify IAM permissions, subnet tags, certificate status, and target health.
- **Cognito login fails:** verify the user pool, app client, domain, callback and logout URLs, and the ingress annotations.
- **DNS is not resolving:** confirm the CNAME points to the current ALB DNS name and allow time for DNS propagation.

## Teardown

Destroying resources can permanently delete data. Back up the database first if its contents must be retained. Remove the Kubernetes Ingress and wait for its ALB resources to be cleaned up before destroying the infrastructure. Remove separately managed IAM resources only after confirming they belong exclusively to this deployment.

From `terraform-infra`, select and verify the intended workspace, then review the destroy plan carefully:

```bash
terraform workspace show
terraform plan -destroy
```

Only after confirming every planned deletion is correct:

```bash
terraform destroy
```

Do not use broad account-wide deletion commands. Preserve the Terraform state backend until the environment is confirmed destroyed and no other environment depends on it.

## Project image

![TaskPulse application](https://github.com/user-attachments/assets/59cdcb07-1a3f-4123-8e5e-ca074b465f65)

---

TaskPulse is a learning project for practicing full-stack development, infrastructure as code, Kubernetes operations, AWS security, and responsible cloud resource management.
