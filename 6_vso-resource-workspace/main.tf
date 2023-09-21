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

provider "vault" {
  # Configuration options
  # address = var.vault_address
  address = "http://${data.kubernetes_service.vault.status[0].load_balancer[0].ingress[0].hostname}:8200"
  token   = var.vault_token
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

resource "kubernetes_namespace" "demo-ns" {
  metadata {
    name = local.k8s_namespace
  }
}

resource "vault_namespace" "test" {
  count = var.vault_enterprise ? 1 : 0
  path  = "${local.name_prefix}-ns"
}

data "kubernetes_namespace" "operator" {
  metadata {
    name = var.operator_namespace
    # name = kubernetes_namespace.vso.metadata.namespace
  }
}

data "kubernetes_namespace" "demo-ns" {
  metadata {
    name = kubernetes_namespace.demo-ns.metadata[0].name
  }
}

data "kubernetes_service" "vault" {
  metadata {
    name      = "vault-ui"
    namespace = "vault"
  }
}

data "kubernetes_service" "static_webapp" {
  metadata {
    name      = "vso-static-demo-svc"
    namespace = "demo-ns"
  }
  depends_on = [ kubernetes_manifest.vault-static-app, kubernetes_manifest.vault-static-svc ]
}