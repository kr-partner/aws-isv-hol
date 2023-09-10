resource "helm_release" "argocd" {
  name        = "argocd"
  namespace   = "argocd"
  repository  = "https://argoproj.github.io/argo-helm"
  version     = "5.45.3"
  chart       = "argo-cd"
  create_namespace = true
  
  set {
    name = "server.service.type"  
    value = "LoadBalancer"
  }
  set {
    name = "server.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-scheme"
    value = "internet-facing"
  }
}

data "kubernetes_service" "argocd" {
  metadata {
    name = "argocd-server"
    namespace = "argocd"
  }
}