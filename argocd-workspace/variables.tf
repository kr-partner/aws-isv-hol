# variable "k8s_config_context" {
#   default = "vault"
# }

variable "k8s_config_path" {
  default = "~/.kube/config"
}

variable "k8s_host" {
  default = "https://kubernetes.default.svc"
}

variable "vault_enterprise" {
  type    = bool
  default = false
}

# variable "vault_address" {}
# variable "vault_token" {}