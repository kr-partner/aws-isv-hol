resource "helm_release" "argocd" {
  name        = "argocd"
  namespace   = "argocd"
  repository  = "https://argoproj.github.io/argo-helm"
  version     = "5.45.3"
  chart       = "argo-cd"
  create_namespace = true
  
  set {
    name = "server.service.type"  
    value = "LoadBalancer"
  }
  set {
    name = "server.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-scheme"
    value = "internet-facing"
  }
}

data "kubernetes_service" "argocd" {
  metadata {
    name = "argocd-server"
    namespace = "argocd"
  }
  depends_on = [helm_release.argocd]
}

resource "kubernetes_manifest" "configmap_argocd_cmp_plugin" {
  manifest = {
    "apiVersion" = "v1"
    "data" = {
      "avp-helm.yaml" = <<-EOT
      apiVersion: argoproj.io/v1alpha1
      kind: ConfigManagementPlugin
      metadata:
        name: argocd-vault-plugin-helm
      spec:
        allowConcurrency: true
      
        # Note: this command is run _before_ any Helm templating is done, therefore the logic is to check
        # if this looks like a Helm chart
        discover:
          find:
            command:
              - sh
              - "-c"
              - "find . -name 'Chart.yaml' && find . -name 'values.yaml'"
        generate:
          command:
            - bash
            - "-c"
            - "helm template $ARGOCD_APP_NAME --include-crds -n $ARGOCD_ENV_HELM_ARGS -f $${ARGOCD_ENV_HELM_VALUES} . | argocd-vault-plugin generate -s argocd:argocd-vault-plugin-credentials"
        lockRepo: false 
      EOT
    }
    "kind" = "ConfigMap"
    "metadata" = {
      "name" = "cmp-plugin"
      "namespace" = "argocd"
    }
  }
  depends_on = [helm_release.argocd]
}

resource "kubernetes_manifest" "secret_argocd_argocd_vault_plugin_credentials" {
  manifest = {
    "apiVersion" = "v1"
    "kind" = "Secret"
    "metadata" = {
      "name" = "argocd-vault-plugin-credentials"
      "namespace" = "argocd"
    }
    "stringData" = {
      "AVP_AUTH_TYPE" = "k8s"
      "AVP_K8S_ROLE" = "argocd"
      "AVP_TYPE" = "vault"
      "VAULT_ADDR" = "http://vault.vault:8200"
    }
    "type" = "Opaque"
  }
  depends_on = [helm_release.argocd]  
}

resource "kubernetes_manifest" "deployment_argocd_argocd_repo_server" {
  manifest = {
    "apiVersion" = "apps/v1"
    "kind" = "Deployment"
    "metadata" = {
      "annotations" = {
        "meta.helm.sh/release-name" = "argocd"
        "meta.helm.sh/release-namespace" = "argocd"
      }
      "generation" = 12
      "labels" = {
        "app.kubernetes.io/component" = "repo-server"
        "app.kubernetes.io/instance" = "argocd"
        "app.kubernetes.io/managed-by" = "Helm"
        "app.kubernetes.io/name" = "argocd-repo-server"
        "app.kubernetes.io/part-of" = "argocd"
        "app.kubernetes.io/version" = "v2.7.11"
        "helm.sh/chart" = "argo-cd-5.42.3"
      }
      "name" = "argocd-repo-server"
      "namespace" = "argocd"
    }
    "spec" = {
      "progressDeadlineSeconds" = 600
      "replicas" = 1
      "revisionHistoryLimit" = 3
      "selector" = {
        "matchLabels" = {
          "app.kubernetes.io/instance" = "argocd"
          "app.kubernetes.io/name" = "argocd-repo-server"
        }
      }
      "strategy" = {
        "rollingUpdate" = {
          "maxSurge" = "25%"
          "maxUnavailable" = "25%"
        }
        "type" = "RollingUpdate"
      }
      "template" = {
        "metadata" = {
          "annotations" = null
          "creationTimestamp" = null
          "labels" = {
            "app.kubernetes.io/component" = "repo-server"
            "app.kubernetes.io/instance" = "argocd"
            "app.kubernetes.io/managed-by" = "Helm"
            "app.kubernetes.io/name" = "argocd-repo-server"
            "app.kubernetes.io/part-of" = "argocd"
            "app.kubernetes.io/version" = "v2.7.11"
            "helm.sh/chart" = "argo-cd-5.42.3"
          }
        }
        "spec" = {
          "affinity" = {
            "podAntiAffinity" = {
              "preferredDuringSchedulingIgnoredDuringExecution" = [
                {
                  "podAffinityTerm" = {
                    "labelSelector" = {
                      "matchLabels" = {
                        "app.kubernetes.io/name" = "argocd-repo-server"
                      }
                    }
                    "topologyKey" = "kubernetes.io/hostname"
                  }
                  "weight" = 100
                },
              ]
            }
          }
          "containers" = [
            {
              "command" = [
                "/var/run/argocd/argocd-cmp-server",
              ]
              "image" = "quay.io/argoproj/argocd:v2.7.4"
              "imagePullPolicy" = "IfNotPresent"
              "name" = "avp-helm"
              "resources" = {}
              "securityContext" = {
                "runAsNonRoot" = true
                "runAsUser" = 999
              }
              "terminationMessagePath" = "/dev/termination-log"
              "terminationMessagePolicy" = "File"
              "volumeMounts" = [
                {
                  "mountPath" = "/var/run/argocd"
                  "name" = "var-files"
                },
                {
                  "mountPath" = "/home/argocd/cmp-server/plugins"
                  "name" = "plugins"
                },
                {
                  "mountPath" = "/tmp"
                  "name" = "tmp"
                },
                {
                  "mountPath" = "/home/argocd/cmp-server/config/plugin.yaml"
                  "name" = "cmp-plugin"
                  "subPath" = "avp-helm.yaml"
                },
                {
                  "mountPath" = "/usr/local/bin/argocd-vault-plugin"
                  "name" = "custom-tools"
                  "subPath" = "argocd-vault-plugin"
                },
              ]
            },
            {
              "args" = [
                "/usr/local/bin/argocd-repo-server",
                "--port=8081",
                "--metrics-port=8084",
              ]
              "env" = [
                {
                  "name" = "ARGOCD_RECONCILIATION_TIMEOUT"
                  "valueFrom" = {
                    "configMapKeyRef" = {
                      "key" = "timeout.reconciliation"
                      "name" = "argocd-cm"
                      "optional" = true
                    }
                  }
                },
                {
                  "name" = "ARGOCD_REPO_SERVER_LOGFORMAT"
                  "valueFrom" = {
                    "configMapKeyRef" = {
                      "key" = "reposerver.log.format"
                      "name" = "argocd-cmd-params-cm"
                      "optional" = true
                    }
                  }
                },
                {
                  "name" = "ARGOCD_REPO_SERVER_LOGLEVEL"
                  "valueFrom" = {
                    "configMapKeyRef" = {
                      "key" = "reposerver.log.level"
                      "name" = "argocd-cmd-params-cm"
                      "optional" = true
                    }
                  }
                },
                {
                  "name" = "ARGOCD_REPO_SERVER_PARALLELISM_LIMIT"
                  "valueFrom" = {
                    "configMapKeyRef" = {
                      "key" = "reposerver.parallelism.limit"
                      "name" = "argocd-cmd-params-cm"
                      "optional" = true
                    }
                  }
                },
                {
                  "name" = "ARGOCD_REPO_SERVER_DISABLE_TLS"
                  "valueFrom" = {
                    "configMapKeyRef" = {
                      "key" = "reposerver.disable.tls"
                      "name" = "argocd-cmd-params-cm"
                      "optional" = true
                    }
                  }
                },
                {
                  "name" = "ARGOCD_TLS_MIN_VERSION"
                  "valueFrom" = {
                    "configMapKeyRef" = {
                      "key" = "reposerver.tls.minversion"
                      "name" = "argocd-cmd-params-cm"
                      "optional" = true
                    }
                  }
                },
                {
                  "name" = "ARGOCD_TLS_MAX_VERSION"
                  "valueFrom" = {
                    "configMapKeyRef" = {
                      "key" = "reposerver.tls.maxversion"
                      "name" = "argocd-cmd-params-cm"
                      "optional" = true
                    }
                  }
                },
                {
                  "name" = "ARGOCD_TLS_CIPHERS"
                  "valueFrom" = {
                    "configMapKeyRef" = {
                      "key" = "reposerver.tls.ciphers"
                      "name" = "argocd-cmd-params-cm"
                      "optional" = true
                    }
                  }
                },
                {
                  "name" = "ARGOCD_REPO_CACHE_EXPIRATION"
                  "valueFrom" = {
                    "configMapKeyRef" = {
                      "key" = "reposerver.repo.cache.expiration"
                      "name" = "argocd-cmd-params-cm"
                      "optional" = true
                    }
                  }
                },
                {
                  "name" = "REDIS_SERVER"
                  "valueFrom" = {
                    "configMapKeyRef" = {
                      "key" = "redis.server"
                      "name" = "argocd-cmd-params-cm"
                      "optional" = true
                    }
                  }
                },
                {
                  "name" = "REDIS_COMPRESSION"
                  "valueFrom" = {
                    "configMapKeyRef" = {
                      "key" = "redis.compression"
                      "name" = "argocd-cmd-params-cm"
                      "optional" = true
                    }
                  }
                },
                {
                  "name" = "REDISDB"
                  "valueFrom" = {
                    "configMapKeyRef" = {
                      "key" = "redis.db"
                      "name" = "argocd-cmd-params-cm"
                      "optional" = true
                    }
                  }
                },
                {
                  "name" = "REDIS_USERNAME"
                  "valueFrom" = {
                    "secretKeyRef" = {
                      "key" = "redis-username"
                      "name" = "argocd-redis"
                      "optional" = true
                    }
                  }
                },
                {
                  "name" = "REDIS_PASSWORD"
                  "valueFrom" = {
                    "secretKeyRef" = {
                      "key" = "redis-password"
                      "name" = "argocd-redis"
                      "optional" = true
                    }
                  }
                },
                {
                  "name" = "ARGOCD_DEFAULT_CACHE_EXPIRATION"
                  "valueFrom" = {
                    "configMapKeyRef" = {
                      "key" = "reposerver.default.cache.expiration"
                      "name" = "argocd-cmd-params-cm"
                      "optional" = true
                    }
                  }
                },
                {
                  "name" = "ARGOCD_REPO_SERVER_OTLP_ADDRESS"
                  "valueFrom" = {
                    "configMapKeyRef" = {
                      "key" = "otlp.address"
                      "name" = "argocd-cmd-params-cm"
                      "optional" = true
                    }
                  }
                },
                {
                  "name" = "ARGOCD_REPO_SERVER_MAX_COMBINED_DIRECTORY_MANIFESTS_SIZE"
                  "valueFrom" = {
                    "configMapKeyRef" = {
                      "key" = "reposerver.max.combined.directory.manifests.size"
                      "name" = "argocd-cmd-params-cm"
                      "optional" = true
                    }
                  }
                },
                {
                  "name" = "ARGOCD_REPO_SERVER_PLUGIN_TAR_EXCLUSIONS"
                  "valueFrom" = {
                    "configMapKeyRef" = {
                      "key" = "reposerver.plugin.tar.exclusions"
                      "name" = "argocd-cmd-params-cm"
                      "optional" = true
                    }
                  }
                },
                {
                  "name" = "ARGOCD_REPO_SERVER_ALLOW_OUT_OF_BOUNDS_SYMLINKS"
                  "valueFrom" = {
                    "configMapKeyRef" = {
                      "key" = "reposerver.allow.oob.symlinks"
                      "name" = "argocd-cmd-params-cm"
                      "optional" = true
                    }
                  }
                },
                {
                  "name" = "ARGOCD_REPO_SERVER_STREAMED_MANIFEST_MAX_TAR_SIZE"
                  "valueFrom" = {
                    "configMapKeyRef" = {
                      "key" = "reposerver.streamed.manifest.max.tar.size"
                      "name" = "argocd-cmd-params-cm"
                      "optional" = true
                    }
                  }
                },
                {
                  "name" = "ARGOCD_REPO_SERVER_STREAMED_MANIFEST_MAX_EXTRACTED_SIZE"
                  "valueFrom" = {
                    "configMapKeyRef" = {
                      "key" = "reposerver.streamed.manifest.max.extracted.size"
                      "name" = "argocd-cmd-params-cm"
                      "optional" = true
                    }
                  }
                },
                {
                  "name" = "ARGOCD_GIT_MODULES_ENABLED"
                  "valueFrom" = {
                    "configMapKeyRef" = {
                      "key" = "reposerver.enable.git.submodule"
                      "name" = "argocd-cmd-params-cm"
                      "optional" = true
                    }
                  }
                },
                {
                  "name" = "HELM_CACHE_HOME"
                  "value" = "/helm-working-dir"
                },
                {
                  "name" = "HELM_CONFIG_HOME"
                  "value" = "/helm-working-dir"
                },
                {
                  "name" = "HELM_DATA_HOME"
                  "value" = "/helm-working-dir"
                },
              ]
              "envFrom" = [
                {
                  "secretRef" = {
                    "name" = "argocd-vault-plugin-credentials"
                  }
                },
              ]
              "image" = "quay.io/argoproj/argocd:v2.7.11"
              "imagePullPolicy" = "IfNotPresent"
              "livenessProbe" = {
                "failureThreshold" = 3
                "httpGet" = {
                  "path" = "/healthz?full=true"
                  "port" = "metrics"
                  "scheme" = "HTTP"
                }
                "initialDelaySeconds" = 10
                "periodSeconds" = 10
                "successThreshold" = 1
                "timeoutSeconds" = 1
              }
              "name" = "repo-server"
              "ports" = [
                {
                  "containerPort" = 8081
                  "name" = "repo-server"
                  "protocol" = "TCP"
                },
                {
                  "containerPort" = 8084
                  "name" = "metrics"
                  "protocol" = "TCP"
                },
              ]
              "readinessProbe" = {
                "failureThreshold" = 3
                "httpGet" = {
                  "path" = "/healthz"
                  "port" = "metrics"
                  "scheme" = "HTTP"
                }
                "initialDelaySeconds" = 10
                "periodSeconds" = 10
                "successThreshold" = 1
                "timeoutSeconds" = 1
              }
              "resources" = {}
              "securityContext" = {
                "allowPrivilegeEscalation" = false
                "capabilities" = {
                  "drop" = [
                    "ALL",
                  ]
                }
                "readOnlyRootFilesystem" = true
                "runAsNonRoot" = true
                "seccompProfile" = {
                  "type" = "RuntimeDefault"
                }
              }
              "terminationMessagePath" = "/dev/termination-log"
              "terminationMessagePolicy" = "File"
              "volumeMounts" = [
                {
                  "mountPath" = "/app/config/ssh"
                  "name" = "ssh-known-hosts"
                },
                {
                  "mountPath" = "/app/config/tls"
                  "name" = "tls-certs"
                },
                {
                  "mountPath" = "/app/config/gpg/source"
                  "name" = "gpg-keys"
                },
                {
                  "mountPath" = "/app/config/gpg/keys"
                  "name" = "gpg-keyring"
                },
                {
                  "mountPath" = "/app/config/reposerver/tls"
                  "name" = "argocd-repo-server-tls"
                },
                {
                  "mountPath" = "/helm-working-dir"
                  "name" = "helm-working-dir"
                },
                {
                  "mountPath" = "/home/argocd/cmp-server/plugins"
                  "name" = "plugins"
                },
                {
                  "mountPath" = "/tmp"
                  "name" = "tmp"
                },
              ]
            },
          ]
          "dnsPolicy" = "ClusterFirst"
          "initContainers" = [
            {
              "args" = [
                "curl -L https://github.com/argoproj-labs/argocd-vault-plugin/releases/download/v$(AVP_VERSION)/argocd-vault-plugin_$(AVP_VERSION)_linux_amd64 -o argocd-vault-plugin && chmod +x argocd-vault-plugin && mv argocd-vault-plugin /custom-tools/",
              ]
              "command" = [
                "sh",
                "-c",
              ]
              "env" = [
                {
                  "name" = "AVP_VERSION"
                  "value" = "1.15.0"
                },
              ]
              "image" = "alpine/curl"
              "imagePullPolicy" = "Always"
              "name" = "download-tools"
              "resources" = {}
              "terminationMessagePath" = "/dev/termination-log"
              "terminationMessagePolicy" = "File"
              "volumeMounts" = [
                {
                  "mountPath" = "/custom-tools"
                  "name" = "custom-tools"
                },
              ]
            },
            {
              "command" = [
                "/bin/cp",
                "-n",
                "/usr/local/bin/argocd",
                "/var/run/argocd/argocd-cmp-server",
              ]
              "image" = "quay.io/argoproj/argocd:v2.7.11"
              "imagePullPolicy" = "IfNotPresent"
              "name" = "copyutil"
              "resources" = {}
              "securityContext" = {
                "allowPrivilegeEscalation" = false
                "capabilities" = {
                  "drop" = [
                    "ALL",
                  ]
                }
                "readOnlyRootFilesystem" = true
                "runAsNonRoot" = true
                "seccompProfile" = {
                  "type" = "RuntimeDefault"
                }
              }
              "terminationMessagePath" = "/dev/termination-log"
              "terminationMessagePolicy" = "File"
              "volumeMounts" = [
                {
                  "mountPath" = "/var/run/argocd"
                  "name" = "var-files"
                },
              ]
            },
          ]
          "restartPolicy" = "Always"
          "schedulerName" = "default-scheduler"
          "securityContext" = {}
          "serviceAccount" = "argocd-repo-server"
          "serviceAccountName" = "argocd-repo-server"
          "terminationGracePeriodSeconds" = 30
          "volumes" = [
            {
              "configMap" = {
                "defaultMode" = 420
                "name" = "cmp-plugin"
              }
              "name" = "cmp-plugin"
            },
            {
              "emptyDir" = {}
              "name" = "custom-tools"
            },
            {
              "emptyDir" = {}
              "name" = "helm-working-dir"
            },
            {
              "emptyDir" = {}
              "name" = "plugins"
            },
            {
              "emptyDir" = {}
              "name" = "var-files"
            },
            {
              "emptyDir" = {}
              "name" = "tmp"
            },
            {
              "configMap" = {
                "defaultMode" = 420
                "name" = "argocd-ssh-known-hosts-cm"
              }
              "name" = "ssh-known-hosts"
            },
            {
              "configMap" = {
                "defaultMode" = 420
                "name" = "argocd-tls-certs-cm"
              }
              "name" = "tls-certs"
            },
            {
              "configMap" = {
                "defaultMode" = 420
                "name" = "argocd-gpg-keys-cm"
              }
              "name" = "gpg-keys"
            },
            {
              "emptyDir" = {}
              "name" = "gpg-keyring"
            },
            {
              "name" = "argocd-repo-server-tls"
              "secret" = {
                "defaultMode" = 420
                "items" = [
                  {
                    "key" = "tls.crt"
                    "path" = "tls.crt"
                  },
                  {
                    "key" = "tls.key"
                    "path" = "tls.key"
                  },
                  {
                    "key" = "ca.crt"
                    "path" = "ca.crt"
                  },
                ]
                "optional" = true
                "secretName" = "argocd-repo-server-tls"
              }
            },
          ]
        }
      }
    }
  }
  depends_on = [helm_release.argocd]  
}