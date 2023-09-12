# variable "k8s_config_context" {
#   default = "vault"
# }

variable "k8s_config_path" {
  default = "~/.kube/config"
}

variable "k8s_host" {
  default = "https://kubernetes.default.svc"
}

# variable "vault_address" {
#   default = "127.0.0.1:8200"
# }

# variable "vault_token" {
#   default = "root"
# }