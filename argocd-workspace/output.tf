output "argocd_external_ip" {
  value = "https://${data.kubernetes_service.argocd.status[0].load_balancer[0].ingress[0].hostname}s"
}