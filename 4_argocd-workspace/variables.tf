# variable "k8s_config_context" {
#   default = "vault"
# }

variable "k8s_config_path" {
  default = "~/.kube/config"
}

variable "k8s_host" {
  default = "https://kubernetes.default.svc"
}

variable "vault_token" {
  default = "root"
}

variable "user" {
  default = "secret_user"
}

variable "passowrd" {
  default = "secret_password"
}