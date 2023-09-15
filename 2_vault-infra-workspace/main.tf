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