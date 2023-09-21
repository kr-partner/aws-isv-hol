output "name_prefix" {
  value = local.name_prefix
}
output "k8s_namespace" {
  value = local.k8s_namespace
}
output "auth_mount" {
  value = local.auth_mount
}
output "auth_policy" {
  value = local.auth_policy
}
output "auth_role" {
  value = local.auth_role
}
output "db_role" {
  value = var.db_role
}
output "db_path" {
  value = vault_database_secrets_mount.db.path
}
#output "k8s_db_secret" {
#  value = kubernetes_secret.db[*].metadata[0].name
#}
output "namespace" {
  value = local.namespace
}
output "vault_external_ip" {
  value = "http://${data.kubernetes_service.vault.status[0].load_balancer[0].ingress[0].hostname}:8200"
}

# output "static_webapp_external_ip" {
#   value = "http://${data.kubernetes_service.static_webapp.status[0].load_balancer[0].ingress[0].hostname}:80"
# }