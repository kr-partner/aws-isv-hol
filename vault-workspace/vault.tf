resource "helm_release" "vault" {
  namespace        = kubernetes_namespace.vault.metadata[0].name
  name             = "vault"
  create_namespace = false
  wait             = true
  wait_for_jobs    = true

  repository = "https://helm.releases.hashicorp.com"
  chart      = "vault"

  set {
    name  = "server.dev.enabled"
    value = "true"
  }
  set {
    name  = "server.dev.devRootToken"
    value = "root"
  }
  set {
    name  = "ui.enabled"
    value = "true"
  }
  set {
    name  = "ui.serviceType"
    value = "LoadBalancer"
  }
  set {
    name  = "ui.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-type"
    value = "nlb"
  }
  set {
    name  = "ui.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-scheme"
    value = "internet-facing"
  }
}

resource "kubernetes_namespace" "vault" {
  metadata {
    name = "vault"
  }
}