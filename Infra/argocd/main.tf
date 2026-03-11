
resource "helm_release" "this" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "9.4.2"
  namespace  = "argocd"
  create_namespace = true
  cleanup_on_fail = false
  values = [
        file("${path.module}/helm_values/values.yaml")
  ]
}

# resource "kubernetes_manifest" "bootstrap" {
#   manifest = yamldecode(file("${path.module}/manifests/bootstrap.yaml"))


#   depends_on = [ helm_release.this ]
# }


# resource "kubernetes_manifest" "argocd_secret" {
#   manifest = yamldecode(file("${path.module}/manifests/argocd_secret.yaml"))

#   depends_on = [ helm_release.this ]
# }