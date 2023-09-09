resource "vault_mount" "kvv2" {
  path        = "kvv2"
  type        = "kv"
  options     = { version = "2" }
  description = "KV Version 2 secret engine mount"
}

resource "vault_kv_secret_v2" "example" {
  mount                      = vault_mount.kvv2.path
  name                       = "kv-v2"
  data_json                  = jsonencode(
  {
    zip       = "zap",
    foo       = "bar"
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