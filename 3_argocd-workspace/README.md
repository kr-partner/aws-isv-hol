# argocd-worspace
argocd 배포 시 사용하는 workspace입니다.

사전에 배포해야 될 사항은 다음과 같습니다.
- EKS
- Vault cluster

## argocd avp(argocd vault plugin) 환경 배포
argocd는 terraform을 이용하여 배포하고 연동되는 정보는 bastion에서 cli로 준비합니다.

### 1. Vault에 테스트 key/value 입력

```
# shell 접속
kubectl exec -n vault vault-0 -it -- sh

# enable kv-v2 engine in Vault
kubectl exec -n vault vault-0 -it -- vault secrets enable kv-v2

# create kv-v2 secret with two keys
kubectl exec -n vault vault-0 -it -- vault kv put kv-v2/demo user="secret_user" password="secret_password"

# create policy to enable reading above secret
kubectl exec -n vault vault-0 -it -- vault policy write demo - <<EOF
path "kv-v2/data/demo" {
  capabilities = ["read"]
}
EOF

exit
```

### 2. argocd vault plugin에서 배포 시 참고 할 kubernetes auth 생성

```
# enable Kubernetes Auth Method
kubectl exec -n vault vault-0 -- vault auth enable kubernetes

kubectl exec -n vault vault-0 -- vault write auth/kubernetes/config \
  token_reviewer_jwt="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
  kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443" \
  kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt

# create authenticate Role for ArgoCD
kubectl exec -n vault vault-0 -- vault write auth/kubernetes/role/argocd \
  bound_service_account_names=argocd-repo-server \
  bound_service_account_namespaces=argocd \
  policies=demo \
  ttl=48h
  
```

### 3. Terraform을 활용한 avp 배포

### 3) [argocd-workspace](../argocd-workspace/)에서 실행

```
terraform init
terraform plan
terraform apply --auto-approve
```

#### terraform으로 리소스 생성이 정상적으로 되지 않을 경우 

```
# argocd helm repository 연동
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# argocd deploy
helm install argocd argo/argo-cd --set server.service.type=LoadBalancer --namespace argocd --create-namespace --version 5.42.3

# cmp-plugin 배포
kubectl apply -f yaml-resources/cmp-plugin.yaml

# repo-server AVP 적용
kubectl delete deploy argocd-repo-server -nargocd
sleep 10
kubectl apply -f yaml-resources/deployment_argocd_argocd_repo_server.yaml

# redis 재기동
kubectl rollout restart deployment argocd-redis -nargocd

# cmp-plugin 재배포
kubectl delete -f yaml-resources/cmp-plugin.yaml      
kubectl apply -f yaml-resources/cmp-plugin.yaml  

# redis 재기동
kubectl rollout restart deployment argocd-redis -nargocd

```

### 4. argocd 정보 확인 및 login

```
# External IP 확인
EXTERNAL_IP=$(k get svc -n argocd argocd-server -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo $EXTERNAL_IP

# admin 계정의 암호 확인
ARGOPW=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo $ARGOPW

```

### 5. sample application 배포

```
cat <<EOF> sample.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: demo-argocd
  namespace: argocd
spec:
  destination:
    namespace: argocd
    server: https://kubernetes.default.svc
  project: default
  source:
    path: infra/helm
    repoURL: https://github.com/hyungwook0221/spring-boot-debug-app
    targetRevision: main
    plugin:
      env:
        - name: HELM_ARGS
          value: '-f override-values.yaml'
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF

kubectl apply -f sample.yaml
```
