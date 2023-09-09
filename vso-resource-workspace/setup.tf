resource "terraform_data" "permission" {
  provisioner "local-exec" {
    interpreter = [ "/bin/bash", "-c" ]
    working_dir = "${path.module}"
    command     = "chmod +x setup.sh"
  }
#   triggers_replace = [
#     terraform_data.create_securitygroup_rules.id
#   ]
}

resource "terraform_data" "setup" {
  provisioner "local-exec" {
    interpreter = [ "/bin/bash", "-c" ]
    working_dir = "${path.module}"
    command     = "./setup.sh"
  }

  triggers_replace = [
    terraform_data.permission
  ]
}