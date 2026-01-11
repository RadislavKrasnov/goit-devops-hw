data "aws_caller_identity" "current" {}

resource "aws_ecr_repository" "this" {
    name = var.ecr_name

    image_scanning_configuration {
        scan_on_push = var.scan_on_push
    }

    tags = {
        Name        = var.ecr_name
        Environment = "lesson-5"
    }
}

resource "aws_ecr_repository_policy" "this" {
    repository = aws_ecr_repository.this.name

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Sid    = "AllowAccountRootAccess"
                Effect = "Allow"
                Principal = {
                    AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
                }
                Action = [
                    "ecr:*"
                ]
            }
        ]
    })
}
