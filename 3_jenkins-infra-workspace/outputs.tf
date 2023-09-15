output "jenkins_external_ip" {
  value = "http://${data.kubernetes_service.jenkins.status[0].load_balancer[0].ingress[0].hostname}:8080"
}

output "token_output" {
  value = local.token_output
}

output "jenkins_password" {
  value     = data.kubernetes_secret.jenkins
  sensitive = true
  # value = nonsensitive(data.kubernetes_secret.jenkins)
}