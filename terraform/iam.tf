# --- Developer IAM User -------------------------------------------------------

resource "aws_iam_user" "dev_view" {
  name = "bedrock-dev-view"
  tags = {
    Project = var.project_tag
  }
}

# Console login
resource "aws_iam_user_login_profile" "dev_view" {
  user                    = aws_iam_user.dev_view.name
  password_reset_required = false
}

# AWS Console ReadOnly access
resource "aws_iam_user_policy_attachment" "readonly" {
  user       = aws_iam_user.dev_view.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# S3 PutObject on assets bucket only
resource "aws_iam_user_policy" "s3_put" {
  name = "bedrock-dev-s3-put"
  user = aws_iam_user.dev_view.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject"]
        Resource = "arn:aws:s3:::bedrock-assets-${var.student_id}/*"
      }
    ]
  })
}

# Programmatic access keys
resource "aws_iam_access_key" "dev_view" {
  user = aws_iam_user.dev_view.name
}

# --- Lambda Execution Role ----------------------------------------------------

resource "aws_iam_role" "lambda_exec" {
  name = "bedrock-lambda-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "lambda.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Project = var.project_tag
  }
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
