
resource "aws_iam_role" "eks_cluster_role" {
  name = "taskpulse-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

# 2. The EKS Cluster
resource "aws_eks_cluster" "taskpulse_cluster" {
  name                      = "taskpulse-cluster"
  role_arn                  = aws_iam_role.eks_cluster_role.arn
  version                   = "1.36"
  enabled_cluster_log_types = ["api", "audit", "authenticator"]

  vpc_config {
    # The control plane needs access to both public and private subnets to route traffic properly
    subnet_ids = [
      aws_subnet.public_az1.id, aws_subnet.public_az2.id,
      aws_subnet.private_az1.id, aws_subnet.private_az2.id
    ]
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = ["152.58.115.128/32"]
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_cloudwatch_log_group.eks_control_plane,
  ]
}

resource "aws_cloudwatch_log_group" "eks_control_plane" {
  name              = "/aws/eks/taskpulse-cluster/cluster"
  retention_in_days = 7

  tags = {
    Name = "taskpulse-eks-control-plane"
  }
}

# 3. IAM Role for EKS Worker Nodes
resource "aws_iam_role" "eks_node_role" {
  name = "taskpulse-eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "ecr_read_only" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_eks_node_group" "taskpulse_nodes" {
  cluster_name    = aws_eks_cluster.taskpulse_cluster.name
  node_group_name = "taskpulse-node-group"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = [aws_subnet.private_az1.id, aws_subnet.private_az2.id]

  capacity_type  = "ON_DEMAND"
  instance_types = ["t3.medium"]            # One small node for learning; scale up only during labs
  ami_type       = "AL2023_x86_64_STANDARD" # Add this exact line

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.ecr_read_only,
  ]
}
