resource "vault_mount" "kv-v2" {
  path        = "jks"
  type        = "kv"
  options     = { version = "2" }
  description = "KV Version 2 secret engine mount"
}

resource "vault_kv_secret_v2" "kv-v2" {
  mount                      = "${vault_mount.kv-v2.path}"
  name                       = "aws/s3"
  data_json                  = jsonencode(
  {
    username       = "object-url",
    password       = "https://songpubket.s3.ap-northeast-2.amazonaws.com/afc6a48cf93e78e27c2f0fd68ab59eb2.png"
  }
  )
}

resource "vault_policy" "demo-auth-policy" {
  name = "demo-auth-policy"
  policy = <<EOT
path "jks/*" {
  capabilities = ["read", "list"]
}
path "aws/sts/federation" {
  capabilities = ["read"]
}
EOT
}
