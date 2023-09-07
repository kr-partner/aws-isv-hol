variable "operator_namespace" {
  default = "vault-secrets-operator-system"
}

# variable "k8s_config_context" {
#   default = "kind-vault-secrets-operator"
# }

variable "k8s_config_path" {
  default = "~/.kube/config"
}

variable "k8s_host" {
  default = "https://kubernetes.default.svc"
}

variable "postgres_secret_name" {
  default = "postgres-postgresql"
}

variable "vault_enterprise" {
  type    = bool
  default = false
}

variable "k8s_db_secret_count" {
  default = 50
}

variable "db_role" {
  default = "dev-postgres"
}

variable "vault_address" {
  # default = "http://vault.vault.svc.cluster.local:8200"
  # default = "${data.kubernetes_service.vault.external_ips}:8200"
  default = "http://${data.kubernetes_service.vault.status[0].load_balancer[0].ingress[0].hostname}:8200"
}
variable "vault_token" {
  default = "root"
}