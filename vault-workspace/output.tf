output "vault_external_ip" {
  value = "http://${data.kubernetes_service.vault.status[0].load_balancer[0].ingress[0].hostname}:8200"
}