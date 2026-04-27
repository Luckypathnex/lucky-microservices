terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
   bucket          = "lucky-terraform-state-12345"  # Replace with your S3 bucket
    key            = "dev/microservices-project/terraform.tfstate"
    region         = "us-east-1"
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