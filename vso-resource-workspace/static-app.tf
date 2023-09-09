# 작성중
resource "kubernetes_manifest" "vault-connection-default" {
  manifest = {
    apiVersion = "secrets.hashicorp.com/v1beta1"
    kind       = "VaultConnection"
    metadata = {
      name      = "default"
      namespace = data.kubernetes_namespace.operator.metadata[0].name
    }
    spec = {
      address = "http://vault.vault.svc.cluster.local:8200"
    }
  }

  field_manager {
    # force field manager conflicts to be overridden
    force_conflicts = true
  }
}

resource "kubernetes_manifest" "vault-static-auth" {
  manifest = {
    apiVersion = "secrets.hashicorp.com/v1beta1"
    kind = "VaultAuth"
    metadata = {
      name = "static-auth"
      # namespace = data.kubernetes_namespace.operator.metadata[0].name
      namespace = data.kubernetes_namespace.demo-ns.metadata[0].name
    }
    spec = {
      method = "kubernetes"
      namespace = vault_auth_backend.default.namespace
      mount = vault_auth_backend.default.path
      kubernetes = {
        role = vault_kubernetes_auth_backend_role.dev.role_name
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

# ====== Static Secrets 시나리오 ======
resource "kubernetes_manifest" "vault-static-secret" {
  manifest = {
    "apiVersion" = "secrets.hashicorp.com/v1beta1"
    "kind" = "VaultStaticSecret"
    "metadata" = {
      "name" = "vault-kvv2-app"
      "namespace" = "demo-ns"
    }
    "spec" = {
      "destination" = {
        "create" = true
        "name" = "secret-kvv2"
      }
      "mount" = "kvv2"
      "path" = "webapp/config"
      "refreshAfter" = "30s"
      "type" = "kv-v2"
      "vaultAuthRef" = "static-auth"
    }
  }
}

resource "kubernetes_manifest" "vault-static-app" {
  manifest = {
    "apiVersion" = "apps/v1"
    "kind" = "Deployment"
    "metadata" = {
      "labels" = {
        "test" = "vso-static-demo"
      }
      "name" = "vso-static-demo"
      "namespace" = "demo-ns"
    }
    "spec" = {
      "replicas" = 1
      "selector" = {
        "matchLabels" = {
          "test" = "vso-static-demo"
        }
      }
      "strategy" = {
        "rollingUpdate" = {
          "maxUnavailable" = 1
        }
      }
      "template" = {
        "metadata" = {
          "labels" = {
            "test" = "vso-static-demo"
          }
        }
        "spec" = {
          "containers" = [
            {
              "args" = [
                "while true; do echo \"===File Copy Pre Check===\"; cat /tmp/empty/index.html; cat /tmp/static-secrets/username >> /tmp/empty/index.html; echo \"<br>\" >> /tmp/empty/index.html; cat /tmp/static-secrets/password >> /tmp/empty/index.html; echo \"<br>\" >> /tmp/empty/index.html; echo \"===File Copy Post Check===\"; cat /tmp/empty/index.html; sleep 30; done;",
              ]
              "command" = [
                "/bin/sh",
                "-c",
              ]
              "image" = "alpine:latest"
              "name" = "vso-static"
              "volumeMounts" = [
                {
                  "mountPath" = "/tmp/empty"
                  "name" = "html"
                },
                {
                  "mountPath" = "/tmp/static-secrets"
                  "name" = "static-secrets"
                },
              ]
            },
            {
              "image" = "nginx:latest"
              "livenessProbe" = {
                "httpGet" = {
                  "httpHeaders" = [
                    {
                      "name" = "X-Custom-Header"
                      "value" = "Awesome"
                    },
                  ]
                  "path" = "/"
                  "port" = 80
                }
                "initialDelaySeconds" = 3
                "periodSeconds" = 3
              }
              "name" = "example"
              # "resources" = {
              #   "limits" = {
              #     "cpu" = "0.5"
              #     "memory" = "512Mi"
              #   }
              #   "requests" = {
              #     "cpu" = "250m"
              #     "memory" = "50Mi"
              #   }
              # }
              "volumeMounts" = [
                {
                  "mountPath" = "/usr/share/nginx/html"
                  "name" = "html"
                  "readOnly" = true
                },
              ]
            },
          ]
          "volumes" = [
            {
              "name" = "static-secrets"
              "secret" = {
                "secretName" = "secret-kvv2"
              }
            },
            {
              "emptyDir" = {}
              "name" = "html"
            },
          ]
        }
      }
    }
  }
}

resource "kubernetes_manifest" "vault-static-svc" {
  manifest = {
    "apiVersion" = "v1"
    "kind" = "Service"
    "metadata" = {
      "name" = "vso-static-demo-svc"
      "namespace" = "demo-ns"
    }
    "spec" = {
      "ports" = [
        {
          "nodePort" = 30080
          "port" = 80
          "targetPort" = 80
        },
      ]
      "selector" = {
        "test" = "vso-static-demo"
      }
      "type" = "NodePort"
    }
  }
}


