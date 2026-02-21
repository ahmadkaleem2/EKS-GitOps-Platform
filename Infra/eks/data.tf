data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    bucket = "terraform-backend-ahmad"
    key    = "Infra/networking.tfstate"
    region = "us-east-1"
  }
}

data "aws_caller_identity" "current" {}