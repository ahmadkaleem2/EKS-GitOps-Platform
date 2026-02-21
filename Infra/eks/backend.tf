terraform {
  
  backend "s3" {
    bucket = "terraform-backend-ahmad"
    key    = "Infra/EKS.tfstate"
    region = "us-east-1"
  }
  
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
  
}


provider "aws" {
  region = "us-east-1"


  default_tags {
    tags = {
      # created_by = local.created_by
      
    }
  }
  
}