# locals 절에서 불필요한 코드 정리필요
locals {
  # common locals
  name_prefix = "demo"
  namespace   = var.vault_enterprise ? vault_namespace.test[0].path_fq : null
}