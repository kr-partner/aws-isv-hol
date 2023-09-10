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