resource "helm_release" "argocd" {
  name        = "argocd"
  namespace   = "argocd"
  repository  = "https://argoproj.github.io/argo-helm"
  version     = "5.45.3"
  chart       = "argo-cd"
  create_namespace = false
  
  set {
    name = "server.service.type"  
    value = "LoadBalancer"
  }
  set {
    name = "server.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-scheme"
    value = "internet-facing"
  }
  depends_on = [kubernetes_namespace.argocd]
}

resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
}

data "kubernetes_service" "argocd" {
  metadata {
    name = "argocd-server"
    namespace = "argocd"
  }
  depends_on = [helm_release.argocd]
}

resource "kubernetes_secret" "secret_argocd_argocd_vault_plugin_credentials" {
  metadata {
    name = "argocd-vault-plugin-credentials"
    namespace = "argocd"
  }

  data = {
    AVP_AUTH_TYPE = "k8s"
    AVP_K8S_ROLE = "argocd"
    AVP_TYPE = "vault"
    VAULT_ADDR = "http://vault.vault:8200"
  }

  type = "Opaque"

  depends_on = [helm_release.argocd]  
}

resource "null_resource" "patch_resource" {
  depends_on = [helm_release.argocd,kubernetes_secret.secret_argocd_argocd_vault_plugin_credentials]  

  triggers = {
    # 리소스를 업데이트하려면 트리거 설정
    configmap_patch = base64sha256(file("${path.module}/yaml-resources/deployment_argocd_argocd_repo_server.yaml"))
  }

  provisioner "local-exec" {
    command = <<-EOT
      kubectl apply -f ${path.module}/yaml-resources/cmp-plugin.yaml
      kubectl delete -f ${path.module}/yaml-resources/deployment_argocd_argocd_repo_server.yaml
      sleep 10
      kubectl apply -f ${path.module}/yaml-resources/deployment_argocd_argocd_repo_server.yaml
      sleep 15
      kubectl rollout restart deployment argocd-redis -nargocd
      kubectl rollout restart deployment argocd-repo-server -nargocd
      kubectl rollout restart deployment argocd-redis -nargocd
      kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
    EOT
  }
}
