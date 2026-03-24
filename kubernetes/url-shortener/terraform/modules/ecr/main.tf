resource "aws_ecr_repository" "shorten" {
  name                 = "url-shortener/shorten"
  image_tag_mutability = "MUTABLE"

  tags = {
    Project     = "url-shortener"
    Environment = var.environment
  }
}

resource "aws_ecr_repository" "redirect" {
  name                 = "url-shortener/redirect"
  image_tag_mutability = "MUTABLE"

  tags = {
    Project     = "url-shortener"
    Environment = var.environment
  }
}

resource "aws_ecr_lifecycle_policy" "shorten" {
  repository = aws_ecr_repository.shorten.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 5 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 5
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

resource "aws_ecr_lifecycle_policy" "redirect" {
  repository = aws_ecr_repository.redirect.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 5 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 5
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
