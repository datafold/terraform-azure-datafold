resource "helm_release" "datafold_crds" {
  name       = "datafold-crds"
  namespace  = local.namespace
  repository = "https://charts.datafold.com"
  chart      = "datafold-crds"
  version    = local.crd_version
}

