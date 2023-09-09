



## Configure Vault
```bash
# Vault Shell 접근
kubectl exec --stdin=true --tty=true vault-0 -n vault -- /bin/sh

# Kubernetes 인증 활성화
# vault auth enable kubernetes

# Kubernetes 인증구성
# vault write auth/kubernetes/config \
#   kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443"

# KV v1 / v2 시크릿엔진 활성화
vault secrets enable -path=kvv2 kv-v2
vault secrets enable -path=kv kv

# 정책추가
vault policy write dev - <<EOF
path "kv/*" {
  capabilities = ["read"]
}

path "kvv2/*" {
  capabilities = ["read"]
}
EOF

# Role 추가
vault write auth/kubernetes/role/role1 \
      bound_service_account_names=default \
      bound_service_account_namespaces=demo-ns \
      policies=dev \
      audience=vault \
      ttl=24h

# KV v1 샘플데이터 추가
vault kv put kv/webapp/config username="static-user" password="static-password"

# KV v2 샘플데이터 추가
vault kv put kvv2/webapp/config username="static-user-kvv2" password="static-password-kvv2"

exit
```