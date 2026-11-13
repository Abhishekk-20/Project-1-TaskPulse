resource "aws_iam_role" "cloudwatch_observability" {
  name = "taskpulse-cloudwatch-observability"

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

resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.cloudwatch_observability.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "xray_write" {
  role       = aws_iam_role.cloudwatch_observability.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess"
}

resource "aws_eks_addon" "cloudwatch_observability" {
  cluster_name = aws_eks_cluster.taskpulse_cluster.name
  addon_name   = "amazon-cloudwatch-observability"

  pod_identity_association {
    role_arn        = aws_iam_role.cloudwatch_observability.arn
    service_account = "cloudwatch-agent"
  }

  depends_on = [
    aws_eks_addon.pod_identity_agent,
    aws_iam_role_policy_attachment.cloudwatch_agent,
    aws_iam_role_policy_attachment.xray_write,
    aws_cloudwatch_log_group.container_insights_application,
    aws_cloudwatch_log_group.container_insights_host,
    aws_cloudwatch_log_group.container_insights_dataplane,
    aws_cloudwatch_log_group.container_insights_performance,
  ]
}

resource "aws_cloudwatch_log_group" "container_insights_application" {
  name              = "/aws/containerinsights/taskpulse-cluster/application"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "container_insights_host" {
  name              = "/aws/containerinsights/taskpulse-cluster/host"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "container_insights_dataplane" {
  name              = "/aws/containerinsights/taskpulse-cluster/dataplane"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "container_insights_performance" {
  name              = "/aws/containerinsights/taskpulse-cluster/performance"
  retention_in_days = 7
}
