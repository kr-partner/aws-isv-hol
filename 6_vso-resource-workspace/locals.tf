locals {
  # common locals
  name_prefix = "jks"
  namespace   = var.vault_enterprise ? vault_namespace.test[0].path_fq : null

  # k8s locals
  k8s_namespace = "${local.name_prefix}-ns"

  # auth locals
  auth_mount         = "${local.name_prefix}-auth-mount"
  auth_policy        = "${local.name_prefix}-auth-policy"
  auth_role          = "${local.name_prefix}-auth-role"
  auth_role_operator = "${local.name_prefix}-auth-role-operator"
}