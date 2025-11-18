terraform {
  
  backend "s3" {
    bucket = "ahmad-terraform-backend"
    key    = "Infra/base_k8s_services.tfstate"
    region = "us-west-2"
  }
  
}


provider "aws" {
  region = "us-west-2"


  default_tags {
    tags = {
      created_by = local.created_by
      
    }
  }
  
}

provider "helm" {
  kubernetes = {
    host                   = data.aws_eks_cluster.eks.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.eks.token
  }
}