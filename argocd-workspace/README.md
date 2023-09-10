# argocd-worspace
argocd 배포 시 사용하는 workspace입니다.

사전에 배포해야 될 사항은 다음과 같습니다.
- EKS
- Vault cluster

## argocd 배포
argocd는 terraform을 이용하여 배포합니다.


### 1. Terraform을 활용한 argocd 배포

### 1) [argocd-workspace](./argocd-workspace/)에서 실행


```
terraform init
terraform plan
terraform apply --auto-approve
```


```
# External IP 확인
EXTERNAL_IP=$(k get svc -n argocd argocd-server -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo $EXTERNAL_IP

# admin 계정의 암호 확인
ARGOPW=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo $ARGOPW

# login
argocd login $EXTERNAL_IP --username admin --password $ARGOPW
```


```
# shell 접속
kubectl exec -n vault vault-0 -it -- sh

# enable kv-v2 engine in Vault
vault secrets enable kv-v2

# create kv-v2 secret with two keys
vault kv put kv-v2/demo user="secret_user" password="secret_password"

# create policy to enable reading above secret
vault policy write demo - <<EOF
path "kv-v2/data/demo" {
  capabilities = ["read"]
}
EOF

exit
```

```
# enable Kubernetes Auth Method
kubectl exec -n vault vault-0 -- vault auth enable kubernetes

# get Kubernetes host address
# K8S_HOST="https://kubernetes.default.svc"
# K8S_HOST="https://$(env | grep KUBERNETES_PORT_443_TCP_ADDR| cut -f2 -d'='):443"
K8S_HOST="https://$( kubectl exec -n vault vault-0 -- env | grep KUBERNETES_PORT_443_TCP_ADDR| cut -f2 -d'='):443"

# get Service Account token from Vault Pod
#SA_TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
SA_TOKEN=$(kubectl exec -n vault vault-0 -- cat /var/run/secrets/kubernetes.io/serviceaccount/token)

# get Service Account CA certificate from Vault Pod
#SA_CERT=$(cat /var/run/secrets/kubernetes.io/serviceaccount/ca.crt)
SA_CERT=$(kubectl exec -n vault vault-0 -- cat /var/run/secrets/kubernetes.io/serviceaccount/ca.crt)

# configure Kubernetes Auth Method
kubectl exec -n vault vault-0 -- vault write auth/kubernetes/config \
    token_reviewer_jwt=$SA_TOKEN \
    kubernetes_host=$K8S_HOST \
    kubernetes_ca_cert=$SA_CERT

# create authenticate Role for ArgoCD
kubectl exec -n vault vault-0 -- vault write auth/kubernetes/role/argocd \
  bound_service_account_names=argocd-repo-server \
  bound_service_account_namespaces=argocd \
  policies=demo \
  ttl=48h
```