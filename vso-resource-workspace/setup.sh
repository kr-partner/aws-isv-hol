set -e

cat <<EOF | kubectl -n vault exec -i vault-0 -- sh -e
# echo "=== Kubernetes Auth 활성화 ==="
# vault auth disable kubernetes
# vault auth enable kubernetes

# echo "=== Kubernetes Auth Config ==="
vault write auth/kubernetes/config \
    kubernetes_host=https://kubernetes.default.svc

echo "=== KV V2 시크릿엔진 활성화 : kv-v2 ==="
vault secrets disable kvv2/
vault secrets enable -path=kvv2 kv-v2

echo "=== Policy 추가 : demo-auth-policy ==="
vault policy write demo-auth-policy - <<EOT
path "kvv2/*" {
  capabilities = ["read"]
}
EOT

echo "=== Role 추가 : demo-auth-role ==="
vault write auth/kubernetes/role/demo-auth-role \
      bound_service_account_names=default \
      bound_service_account_namespaces=demo-ns \
      policies=demo-auth-policy \
      audience=vault \
      ttl=24h

echo "=== KV v2 샘플 데이터 추가 : username/password ==="
vault kv put kvv2/webapp/config username="static-user-kvv2" password="static-password-kvv2"

EOF