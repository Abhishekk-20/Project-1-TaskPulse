resource "aws_ecr_repository" "taskpulse_backend" {
  name                 = "taskpulse-backend"
  image_tag_mutability = "IMMUTABLE"
  force_delete         = false
}

resource "aws_ecr_repository" "taskpulse_frontend" {
  name                 = "taskpulse-frontend"
  image_tag_mutability = "IMMUTABLE"
  force_delete         = false
}

resource "aws_ecr_lifecycle_policy" "backend" {
  repository = aws_ecr_repository.taskpulse_backend.name
  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images after one week"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 7
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 2
        description  = "Keep the 30 most recent backend images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 30
        }
        action = { type = "expire" }
      }
    ]
  })
}

resource "aws_ecr_lifecycle_policy" "frontend" {
  repository = aws_ecr_repository.taskpulse_frontend.name
  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images after one week"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 7
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 2
        description  = "Keep the 30 most recent frontend images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 30
        }
        action = { type = "expire" }
      }
    ]
  })
}
