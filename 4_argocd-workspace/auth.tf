# kubernetes auth config
resource "vault_auth_backend" "argo_auth" {
  type = "kubernetes"
}

resource "vault_kubernetes_auth_backend_config" "argo_auth_config" {
  backend                = vault_auth_backend.argo_auth.path
  kubernetes_host        = var.k8s_host
  disable_iss_validation = true
}

# kubernetes auth roles
resource "vault_kubernetes_auth_backend_role" "argo_auth_role" {
  # namespace                        = vault_auth_backend.default.namespace
  backend                     = vault_kubernetes_auth_backend_config.argo_auth_config.backend
  role_name                   = "argocd"
  bound_service_account_names = ["argocd-repo-server"]
  # bound_service_account_namespaces = [kubernetes_namespace.dev.metadata[0].name]
  bound_service_account_namespaces = ["argocd"]
  token_period                     = 0
  token_max_ttl                    = 120
  token_policies = [
    vault_policy.demo-policy.name,
  ]
}