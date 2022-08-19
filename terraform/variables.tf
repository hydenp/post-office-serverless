# determine the environment, default to dev for local
variable "environment" {
  type        = string
  description = "The environment the resource pertains to, dev or prod"
  default     = "dev"
}

locals {
  app_name            = "post-office-tf"
  secret_name         = "${local.app_name}/google_secrets/${var.environment}"
  ecr_repository_name = "${local.app_name}-${var.environment}"
  ecr_image_tag       = "latest"
  lambda_role         = "${local.app_name}-lambda-role-${var.environment}"
}

# AWS Credentials
variable "aws_region" {
  description = "AWS region for all terraform infrastructure"
  default     = "us-west-1"
}

variable "aws_account_id" {
  type      = number
  sensitive = true
}

variable "AWS_SECRET_ACCESS_KEY" {
  type      = string
  sensitive = true
}

variable "AWS_ACCESS_KEY_ID" {
  type      = string
  sensitive = true
}


# Secret variables used by Secrets Manager
variable "google_client_id" {
  description = "Google API Client ID"
  type        = string
  sensitive   = true
}

variable "google_client_secret" {
  description = "Google API Client Secret"
  type        = string
  sensitive   = true
}
