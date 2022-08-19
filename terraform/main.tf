##################################################
# AWS Provider

provider "aws" {
  region     = var.aws_region
  access_key = var.AWS_ACCESS_KEY_ID
  secret_key = var.AWS_SECRET_ACCESS_KEY
}

##################################################
# SecretsManager Provisioning
resource "aws_secretsmanager_secret" "post_office_secrets" {
  name = secret_name
}

# Creating a AWS secret versions for aws
resource "aws_secretsmanager_secret_version" "secrets_version" {
  secret_id     = aws_secretsmanager_secret.post_office_secrets.id
  secret_string = <<EOF
   {
    "google_client_id": "${var.google_client_id}",
    "google_client_secret": "${var.google_client_secret}"
   }
  EOF
}


##################################################
# ECR Provisioning
resource "aws_ecr_repository" "lambda_ecr_repo" {
  name = local.ecr_repository_name
}

data "aws_ecr_image" "lambda_image" {
  repository_name = local.ecr_repository_name
  image_tag       = local.ecr_image_tag
}


##################################################
# Lambda Function Provisioning
data "aws_ecr_image" "lambda_image" {
  repository_name = local.ecr_repository_name
  image_tag       = local.ecr_image_tag
}

resource "aws_iam_role" "lambda_role" {
  name               = local.lambda_role
  assume_role_policy = <<EOF
{
   "Version": "2012-10-17",
   "Statement": [
       {
           "Action": "sts:AssumeRole",
           "Principal": {
               "Service": "lambda.amazonaws.com"
           },
           "Effect": "Allow"
       }
   ]
}
 EOF
}

data "aws_iam_policy_document" "lambda_policy_document" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    effect    = "Allow"
    resources = ["*"]
    sid       = "CreateCloudWatchLogs"
  }
}

resource "aws_iam_policy" "lambda_policy" {
  name   = "${local.app_name}-lambda-policy-${var.environment}"
  path   = "/"
  policy = data.aws_iam_policy_document.lambda_policy_document.json
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = local.lambda_role
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Add permission to fetch the secrets
resource "aws_iam_role_policy" "secrets_manager_role_policy" {
  depends_on = [
    aws_secretsmanager_secret.post_office_secrets
  ]

  name = "secret_manager_access_permissions"
  role = local.lambda_role

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue",
        ]
        Effect   = "Allow"
        Resource = aws_secretsmanager_secret.post_office_secrets.arn
      },
    ]
  })
}

# create the actual lambda function
resource "aws_lambda_function" "lambda_function" {
  function_name = "${local.app_name}-${var.environment}"
  role          = aws_iam_role.lambda_role.arn
  timeout       = 300 # 5-minute timeout
  image_uri     = "${aws_ecr_repository.lambda_ecr_repo.repository_url}@${data.aws_ecr_image.lambda_image.id}"
  package_type  = "Image"
}

# outputs
output "secrets_manager_secret_name" {
  value = aws_secretsmanager_secret.post_office_secrets.name
}

output "lambda_ecr_repo_url" {
  value = aws_ecr_repository.lambda_ecr_repo.repository_url
}

output "lambda_function_name" {
  value = aws_lambda_function.lambda_function.function_name
}
