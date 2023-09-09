resource "vault_mount" "kvv2" {
  path        = "kvv2"
  type        = "kv"
  options     = { version = "2" }
  description = "KV Version 2 secret engine mount"
}

resource "vault_kv_secret_v2" "example" {
  mount                      = "${vault_mount.kvv2.path}"
  name                       = "webapp/config"
  data_json                  = jsonencode(
  {
    username       = "static-user-kvv2",
    password       = "static-password-kvv2"
  }
  )
}

resource "vault_policy" "demo-auth-policy" {
  name = "demo-auth-policy"
  policy = <<EOT
path "kvv2/*" {
  capabilities = ["read"]
}
EOT
}
