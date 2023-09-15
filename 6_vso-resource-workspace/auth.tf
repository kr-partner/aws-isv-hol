# kubernetes auth config
resource "vault_auth_backend" "default" {
  namespace = local.namespace
  # demo-auth-mount/
  path = local.auth_mount
  type = "kubernetes"
}

resource "vault_kubernetes_auth_backend_config" "dev" {
  # namespace              = vault_auth_backend.default.namespace
  backend                = vault_auth_backend.default.path
  kubernetes_host        = var.k8s_host
  disable_iss_validation = true
}

# kubernetes auth roles
resource "vault_kubernetes_auth_backend_role" "db" {
  # namespace                        = vault_auth_backend.default.namespace
  backend                     = vault_kubernetes_auth_backend_config.db.backend
  role_name                   = local.auth_role
  bound_service_account_names = ["default"]
  # bound_service_account_namespaces = [kubernetes_namespace.dev.metadata[0].name]
  bound_service_account_namespaces = [kubernetes_namespace.demo-ns.metadata[0].name]
  token_period                     = 0
  token_max_ttl                    = 120
  token_policies = [
    vault_policy.db.name,
    # vault_policy.demo-auth-policy.name,
  ]
  audience = "vault"
}

resource "vault_kubernetes_auth_backend_role" "operator" {
  # namespace                        = vault_auth_backend.default.namespace
  backend                          = vault_kubernetes_auth_backend_config.dev.backend
  role_name                        = local.auth_role_operator
  bound_service_account_names      = [kubernetes_service_account.operator.metadata[0].name]
  bound_service_account_namespaces = [data.kubernetes_namespace.operator.metadata[0].name]
  token_period                     = 120
  token_policies = [
    vault_policy.operator.name,
  ]
  audience = "vault"
}

# === Dynamic 추가 === 

# resource "vault_auth_backend" "dynamic" {
#   # namespace = local.namespace
#   # demo-auth-mount/
#   path      = local.auth_mount
#   type      = "kubernetes"
# }

resource "vault_kubernetes_auth_backend_config" "db" {
  # namespace              = vault_auth_backend.default.namespace
  backend                = vault_auth_backend.default.path
  kubernetes_host        = var.k8s_host
  disable_iss_validation = true
}

# kubernetes auth roles
resource "vault_kubernetes_auth_backend_role" "dev" {
  namespace                   = vault_auth_backend.default.namespace
  backend                     = vault_kubernetes_auth_backend_config.dev.backend
  role_name                   = local.auth_role
  bound_service_account_names = ["default"]
  # bound_service_account_namespaces = [kubernetes_namespace.dev.metadata[0].name]
  bound_service_account_namespaces = [kubernetes_namespace.demo-ns.metadata[0].name]
  token_period                     = 120
  token_policies = [
    # vault_policy.db.name,
    vault_policy.demo-auth-policy.name,
  ]
  audience = "vault"
}
