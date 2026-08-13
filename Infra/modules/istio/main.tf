resource "helm_release" "istio_base" {
  name             = "istio-base"
  chart            = "oci://gcr.io/istio-release/charts/base"
  version          = var.istio_version
  namespace        = var.namespace
  create_namespace = true
  cleanup_on_fail  = false

  set = [
    for k, v in var.istio_base_values : {
      name  = k
      value = v
    }
  ]
}

resource "helm_release" "istiod" {
  name             = "istiod"
  chart            = "oci://gcr.io/istio-release/charts/istiod"
  version          = var.istio_version
  namespace        = var.namespace
  create_namespace = true
  cleanup_on_fail  = false

  depends_on = [
    helm_release.istio_base
  ]

  set = [
    for k, v in var.istiod_values : {
      name  = k
      value = v
    }
  ]
}