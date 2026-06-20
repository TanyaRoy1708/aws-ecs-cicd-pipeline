terraform {
  required_version = ">= 1.5.0"

  # ── Remote State Backend (S3 + DynamoDB) ──────────────────
  # Run scripts/bootstrap-backend.sh BEFORE first terraform init
  backend "s3" {
    bucket         = "devops-toolbox-terraform-state"
    key            = "devops-toolbox/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "devops-toolbox-terraform-locks"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
