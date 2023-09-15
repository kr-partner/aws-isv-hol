# Done
# resource "kubernetes_manifest" "vault-connection-default" {
#   manifest = {
#     apiVersion = "secrets.hashicorp.com/v1beta1"
#     kind       = "VaultConnection"
#     metadata = {
#       name      = "default"
#       namespace = data.kubernetes_namespace.operator.metadata[0].name
#     }
#     spec = {
#       address = "http://vault.vault.svc.cluster.local:8200"
#     }
#   }

#   field_manager {
#     # force field manager conflicts to be overridden
#     force_conflicts = true
#   }
# }

# Done
resource "kubernetes_manifest" "vault-auth-default" {
  manifest = {
    apiVersion = "secrets.hashicorp.com/v1beta1"
    kind       = "VaultAuth"
    metadata = {
      # name      = "default"
      name      = "dynamic-auth"
      namespace = data.kubernetes_namespace.demo-ns.metadata[0].name
    }
    spec = {
      method    = "kubernetes"
      namespace = vault_auth_backend.default.namespace
      mount     = vault_auth_backend.default.path
      kubernetes = {
        # role           = vault_kubernetes_auth_backend_role.dev.role_name
        role           = vault_kubernetes_auth_backend_role.db.role_name
        serviceAccount = "default"
        audiences = [
          "vault",
        ]
      }
    }
  }

  field_manager {
    # force field manager conflicts to be overridden
    force_conflicts = true
  }
}

# ====== Dynamic Secrets 시나리오 ======
resource "kubernetes_manifest" "vault-dynimic-secret" {
  manifest = {
    apiVersion = "secrets.hashicorp.com/v1beta1"
    kind       = "VaultDynamicSecret"
    metadata = {
      name = "vso-db-demo"
      # namespace = kubernetes_namespace.dev.metadata[0].name
      namespace = kubernetes_namespace.demo-ns.metadata[0].name
    }
    spec = {
      # namespace = vault_auth_backend.default.namespace
      namespace    = vault_auth_backend.default.namespace
      mount        = vault_database_secrets_mount.db.path
      path         = local.db_creds_path
      vaultAuthRef = "dynamic-auth"
      destination = {
        create : false
        name : kubernetes_secret.db.metadata[0].name
      }

      rolloutRestartTargets = [
        {
          kind = "Deployment"
          name = "vso-db-demo"
        }
      ]
    }
  }
}

resource "kubernetes_secret" "db" {
  metadata {
    name = "vso-db-demo"
    # namespace = kubernetes_namespace.dev.metadata[0].name
    namespace = kubernetes_namespace.demo-ns.metadata[0].name
  }
}

resource "kubernetes_deployment" "example" {
  metadata {
    name = "vso-db-demo"
    # namespace = kubernetes_namespace.dev.metadata[0].name
    namespace = kubernetes_namespace.demo-ns.metadata[0].name
    labels = {
      test = "vso-db-demo"
    }
  }

  spec {
    replicas = 1

    # strategy {
    #   rolling_update {
    #     max_unavailable = "1"
    #   }
    # }

    selector {
      match_labels = {
        test = "vso-db-demo"
      }
    }

    template {
      metadata {
        labels = {
          test = "vso-db-demo"
        }
      }

      spec {
        volume {
          name = "secrets"
          secret {
            secret_name = kubernetes_secret.db.metadata[0].name
          }
        }
        container {
          image = "postgres:latest"
          name  = "demo"
          command = [
            "sh", "-c", "while : ; do psql postgresql://$PGUSERNAME@${local.postgres_host}/postgres?sslmode=disable -c 'select 1;' ; sleep 10; done"
          ]

          env {
            name = "PGPASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.db.metadata[0].name
                key  = "password"
              }
            }
          }

          env {
            name = "PGUSERNAME"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.db.metadata[0].name
                key  = "username"
              }
            }
          }

          volume_mount {
            name       = "secrets"
            mount_path = "/etc/secrets"
            read_only  = true
          }

          # resources {
          #   limits = {
          #     cpu    = "0.5"
          #     memory = "64Mi"
          #   }
          #   requests = {
          #     cpu    = "250m"
          #     memory = "50Mi"
          #   }
          # }
        }
      }
    }
  }
}

# Transit Vault Auth Operator
# resource "kubernetes_manifest" "vault-auth-default-operator" {
#   manifest = {
#     apiVersion = "secrets.hashicorp.com/v1beta1"
#     kind       = "VaultAuth"
#     metadata = {
#       name      = "transit-auth"
#       # namespace = data.kubernetes_namespace.demo-ns.metadata[0].name
#       namespace = "vault-secrets-operator"
#     }
#     spec = {
#       method    = "kubernetes"
#       mount     = vault_auth_backend.default.path
#       kubernetes = {
#         # role           = vault_kubernetes_auth_backend_role.dev.role_name
#         role           = vault_kubernetes_auth_backend_role.operator.role_name
#         serviceAccount = "demo-operator"
#         audiences = [
#           "vault",
#         ]
#       }
#       storageEncryption = {
#         mount = "demo-transit"
#         keyName = "vso-client-cache"
#       }
#     }
#   }

#   field_manager {
#     # force field manager conflicts to be overridden
#     force_conflicts = true
#   }
# }

# SA 추가 : demo-operator
# resource "kubernetes_manifest" "transit-service-account" {
#   manifest = {
#     apiVersion = "v1"
#     kind       = "ServiceAccount"
#     metadata = {
#       name      = "demo-operator"
#       namespace = "vault-secrets-operator-system"
#     }
#   }

#   field_manager {
#     # force field manager conflicts to be overridden
#     force_conflicts = true
#   }
# }