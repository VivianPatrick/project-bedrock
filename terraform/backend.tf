terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "project-bedrock-tfstate-4699-v2"
    key    = "project-bedrock/terraform.tfstate"
    region = "us-east-1"
  }
}