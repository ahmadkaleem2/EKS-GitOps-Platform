



resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = var.namespace
  create_namespace = true
  cleanup_on_fail = true

  set = [for k,v in var.albc_values : {
    name  = k
    value = v
  }]
}

locals {
  
}