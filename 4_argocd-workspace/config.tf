resource "vault_mount" "argo_kvv2" {
  path        = "kv-v2"
  type        = "kv"
  options     = { version = "2" }
  description = "KV Version 2 secret engine mount"
}

resource "vault_kv_secret_v2" "kv-v2" {
  mount = vault_mount.argo_kvv2.path
  name  = "demo"
  data_json = jsonencode(
    {
      user = "secret_user",
      password = "secret_password"
    }
  )
}

resource "vault_policy" "demo-policy" {
  name   = "demo"
  policy = <<EOT
path "kv-v2/data/demo" {
  capabilities = ["read"]
}
EOT
}
