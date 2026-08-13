locals {
  helm_set = {}
}

resource "helm_release" "this" {
  name             = "nvidia-device-plugin"
  repository       = "https://nvidia.github.io/k8s-device-plugin"
  chart            = "nvidia-device-plugin"
  version          = var.chart_version
  namespace        = var.namespace
  create_namespace = true
  cleanup_on_fail  = false

  set = [
    for k, v in merge(var.values, local.helm_set) : {
      name  = k
      value = v
    }
  ]
}