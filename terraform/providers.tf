terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "your-terraform-state-bucket"  # Replace with your S3 bucket
    key            = "dev/microservices-project/terraform.tfstate"
    region         = "eu-west-2"
    encrypt        = true
    dynamodb_table = "terraform-locks"  # Optional, for locking
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = local.common_tags
  }
}

locals {
  common_tags = {
    Project     = "microservices-project"
    Environment = var.environment
    Owner       = "dev-team"
    CostCenter  = "engineering"
    ManagedBy   = "terraform"
  }
}