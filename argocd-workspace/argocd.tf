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
  depends_on = [helm_release.argocd]
}

resource "kubernetes_manifest" "configmap_argocd_cmp_plugin" {
  manifest = {
    "apiVersion" = "v1"
    "data" = {
      "avp-helm.yaml" = <<-EOT
      apiVersion: argoproj.io/v1alpha1
      kind: ConfigManagementPlugin
      metadata:
        name: argocd-vault-plugin-helm
      spec:
        allowConcurrency: true
      
        # Note: this command is run _before_ any Helm templating is done, therefore the logic is to check
        # if this looks like a Helm chart
        discover:
          find:
            command:
              - sh
              - "-c"
              - "find . -name 'Chart.yaml' && find . -name 'values.yaml'"
        generate:
          command:
            - bash
            - "-c"
            - "helm template $ARGOCD_APP_NAME --include-crds -n $ARGOCD_ENV_HELM_ARGS -f $${ARGOCD_ENV_HELM_VALUES} . | argocd-vault-plugin generate -s argocd:argocd-vault-plugin-credentials"
        lockRepo: false 
      EOT
    }
    "kind" = "ConfigMap"
    "metadata" = {
      "name" = "cmp-plugin"
      "namespace" = "argocd"
    }
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

resource "null_resource" "patch_configmap" {
  triggers = {
    # 리소스를 업데이트하려면 트리거 설정
    configmap_patch = base64sha256(file("${path.module}/yaml-resources/deployment_argocd_argocd_repo_server.yaml"))
  }

  provisioner "local-exec" {
    command = <<-EOT
      kubectl delete -f ${path.module}/yaml-resources/deployment_argocd_argocd_repo_server.yaml
      sleep 10
      kubectl apply -f ${path.module}/yaml-resources/deployment_argocd_argocd_repo_server.yaml
    EOT
  }
}
