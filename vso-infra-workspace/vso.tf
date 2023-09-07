resource "helm_release" "vso" {
  namespace        = kubernetes_namespace.vso.metadata[0].name
  name             = "vault-secrets-operator-system"
  create_namespace = false
  wait             = true
  wait_for_jobs    = true

  repository = "https://helm.releases.hashicorp.com"
  chart      = "vault-secrets-operator"

  set {
    name  = "defaultVaultConnection.enabled"
    value = "false"
  }
  set {
    name  = "defaultVaultConnection.address"
    value = "http://vault.vault.svc.cluster.local:8200"
  }
  set {
    name  = "defaultVaultConnection.skipTLSVerify"
    value = "false"
  }
}

resource "kubernetes_namespace" "vso" {
  metadata {
    name = "vault-secrets-operator-system"
  }
}