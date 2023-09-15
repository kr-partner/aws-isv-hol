terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "2.11.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.23.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "3.20.0"
    }
  }
}

provider "helm" {
  kubernetes {
    # config_context = var.k8s_config_context
    config_path = var.k8s_config_path
  }
}

provider "kubernetes" {
  # config_context = var.k8s_config_context
  config_path = var.k8s_config_path
}

provider "vault" {
  address = "http://${data.kubernetes_service.vault.status[0].load_balancer[0].ingress[0].hostname}:8200"
  token   = var.vault_token
}

data "kubernetes_service" "vault" {
  metadata {
    name      = "vault-ui"
    namespace = "vault"
  }
}