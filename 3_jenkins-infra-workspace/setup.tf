# 실습에서 사용할 userpass 방식의 계정으로 로그인 후 Token 발행
resource "terraform_data" "userpass_token" {
  provisioner "local-exec" {
    command = "kubectl exec -it -n vault vault-0 -- vault login -method=userpass username=jenkins password=jenkinspwd | grep token | grep hvs > token.txt"
  }

  provisioner "local-exec" {
    command = "kubectl exec -it -n vault vault-0 -- vault login root"
  }

  # triggers_replace = [
  #   vault_auth_backend.userpass
  # ]
  depends_on = [terraform_data.write_jenkinsuser]
}

data "local_file" "output" {
  filename   = "${path.module}/token.txt"
  depends_on = [terraform_data.userpass_token]
}

locals {
  token_output = data.local_file.output.content
  depends_on   = [vault_auth_backend.userpass]
}

# output "terraform_data_output" {
#   value = terraform_data.userpass_token.output 
# }