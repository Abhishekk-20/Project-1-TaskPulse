output "vpc_id" {
  description = "The ID of the TaskPulse VPC"
  value       = aws_vpc.taskpulse_vpc.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets (for ALBs and NAT)"
  value       = [aws_subnet.public_az1.id, aws_subnet.public_az2.id]
}

output "private_subnet_ids" {
  description = "IDs of the private subnets (for EKS Worker Nodes)"
  value       = [aws_subnet.private_az1.id, aws_subnet.private_az2.id]
}

output "isolated_subnet_ids" {
  description = "IDs of the isolated subnets (for RDS PostgreSQL)"
  value       = [aws_subnet.isolated_az1.id, aws_subnet.isolated_az2.id]
}

output "rds_endpoint" {
  description = "The connection endpoint for the RDS PostgreSQL database"
  value       = aws_db_instance.taskpulse_postgres.endpoint
}

output "secrets_manager_arn" {
  description = "The ARN of the RDS-managed master password secret"
  value       = aws_db_instance.taskpulse_postgres.master_user_secret[0].secret_arn
  sensitive   = true
}

output "eks_cluster_name" {
  description = "The name of the EKS cluster"
  value       = aws_eks_cluster.taskpulse_cluster.name
}

output "eks_cluster_endpoint" {
  description = "The endpoint for your Kubernetes API server"
  value       = aws_eks_cluster.taskpulse_cluster.endpoint
}

output "cognito_user_pool_arn" {
  description = "User pool ARN for the ALB authentication annotation"
  value       = aws_cognito_user_pool.taskpulse.arn
}

output "cognito_client_id" {
  description = "User pool app client ID for the ALB authentication annotation"
  value       = aws_cognito_user_pool_client.taskpulse_alb.id
}

output "cognito_domain_prefix" {
  description = "Cognito hosted UI domain prefix for the ALB authentication annotation"
  value       = "taskpulse-${random_id.cognito_domain.hex}"
}
