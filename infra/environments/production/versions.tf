terraform {
  required_version = ">= 1.9"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # リモートステート（S3 + DynamoDBロック）。
  # バケット名/テーブル名/リージョンはアカウント固有値のため、init時に
  # `-backend-config`（またはbackend.hcl）で注入する。一度限りの作成手順は
  # infra/BOOTSTRAP.md を参照。
  # bucket / region / dynamodb_table はアカウント固有値のため、
  # `terraform init -backend-config=backend.hcl`（BOOTSTRAP.md参照）で注入する。
  backend "s3" {
    key     = "attendance-saas/production/terraform.tfstate"
    encrypt = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}
