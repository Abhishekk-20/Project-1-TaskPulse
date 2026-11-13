
resource "aws_security_group" "rds_sg" {
  name        = "taskpulse-rds-sg"
  description = "Allow inbound PostgreSQL traffic only from the Application Tier"
  vpc_id      = aws_vpc.taskpulse_vpc.id

  ingress {
    description     = "PostgreSQL access from EKS nodes"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_eks_cluster.taskpulse_cluster.vpc_config[0].cluster_security_group_id]
  }

  tags = {
    Name = "taskpulse-rds-sg"
  }
}


resource "aws_db_subnet_group" "isolated_db_subnet_group" {
  name       = "taskpulse-isolated-db-subnet-group"
  subnet_ids = [aws_subnet.isolated_az1.id, aws_subnet.isolated_az2.id]

  tags = {
    Name = "TaskPulse Isolated DB Subnets"
  }
}


resource "aws_db_instance" "taskpulse_postgres" {
  identifier                          = "taskpulse-db"
  engine                              = "postgres"
  engine_version                      = "15"
  instance_class                      = "db.t3.micro"
  allocated_storage                   = 20
  db_name                             = "taskpulse"
  username                            = "taskpulseadmin"
  manage_master_user_password         = true
  db_subnet_group_name                = aws_db_subnet_group.isolated_db_subnet_group.name
  vpc_security_group_ids              = [aws_security_group.rds_sg.id]
  publicly_accessible                 = false
  storage_encrypted                   = true
  backup_retention_period             = 1
  deletion_protection                 = false
  skip_final_snapshot                 = true
  final_snapshot_identifier           = "taskpulse-db-final-prod-20261111"
  multi_az                            = false # Learning profile: Single-AZ; use true for production
  iam_database_authentication_enabled = true
  enabled_cloudwatch_logs_exports     = ["postgresql", "upgrade"]
  depends_on                          = [aws_cloudwatch_log_group.rds_postgresql]

  tags = {
    Name = "taskpulse-database"
  }
}

resource "aws_cloudwatch_log_group" "rds_postgresql" {
  name              = "/aws/rds/instance/taskpulse-db/postgresql"
  retention_in_days = 30

  tags = {
    Name = "taskpulse-rds-postgresql"
  }
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "taskpulse_backend_pod" {
  name = "taskpulse-backend-rds-iam"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "pods.eks.amazonaws.com" }
      Action    = ["sts:AssumeRole", "sts:TagSession"]
      Condition = {
        StringEquals = {
          "aws:SourceAccount" = data.aws_caller_identity.current.account_id
        }
        ArnEquals = {
          "aws:SourceArn" = aws_eks_cluster.taskpulse_cluster.arn
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "taskpulse_backend_rds_connect" {
  name = "taskpulse-backend-rds-connect"
  role = aws_iam_role.taskpulse_backend_pod.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "rds-db:connect"
      Resource = "arn:aws:rds-db:ap-south-1:${data.aws_caller_identity.current.account_id}:dbuser:${aws_db_instance.taskpulse_postgres.resource_id}/taskpulse_app"
    }]
  })
}

resource "aws_eks_addon" "pod_identity_agent" {
  cluster_name = aws_eks_cluster.taskpulse_cluster.name
  addon_name   = "eks-pod-identity-agent"
}

resource "aws_eks_pod_identity_association" "taskpulse_backend" {
  cluster_name    = aws_eks_cluster.taskpulse_cluster.name
  namespace       = "default"
  service_account = "taskpulse-backend"
  role_arn        = aws_iam_role.taskpulse_backend_pod.arn

  depends_on = [
    aws_eks_addon.pod_identity_agent,
    aws_iam_role_policy.taskpulse_backend_rds_connect,
  ]
}
