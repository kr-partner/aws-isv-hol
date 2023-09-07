# AWS-ISV-HOL 저장소
본 저장소는 **AWS Cloud Migration & App Modernization을 위한 ISV(SaaS) 솔루션 컨퍼런스**의 HashiCorp Vault 핸즈온 세션을 위한 저장소 입니다.

본 핸즈온 워크샵에서는 이러한 위협 요소를 해소하기 위한 HashiCorp Vault 기반의 DevSecOps 구현을 위한 방법을 알아봅니다. [[등록 페이지]](https://events.hashicorp.com/0914hashicorpworkshop)

## **[ 시간 및 장소 ]**
- 일자 : 23.09.14 (목)
- 시간 : 09:00 ~ 12:00
- 장소: 역삼 센터필드 AWS Training Center 

## **[ 목차 ]**
- OT 및 소개
- DevSecOps 이해와 HashiCorp Vault 소개
- Vault Use Cases 기반의 핸즈온 실습 (Jenkins / ArgoCD / VSO (Vault Secrets Operator) / AWS Lambda)

## **[ 상세정보 ]**
- CI/CD : Jenkins 기반의 빌드, ArgoCD 기반의 배포단계 보안 강화방안
- Kubernetes : VSO(Vault Secrets Operator) 기반의 Seamless한 K8s Secret 관리방안
- Serverless : AWS Lambda Extension을 활용한 서버리스 보안

## **[운영진]**
- 강사 : HashiCorp - 유형욱, 나지훈
- 조력자 : MZC - 이웅희, 나의목, 이송, 김예지

---

# 사용 가이드

## Create EKS Cluster

terraform directory에서 실행

```
terraform init
terraform plan
terraform apply --auto-approve
```

## Validation EKS Cluster

Bastion Host에 접속 후 확인합니다.

### EKS Cluster kubeconfig 설정
```
aws eks --region $AWS_DEFAULT_REGION update-kubeconfig --name $CLUSTER_NAME --kubeconfig ~/.kube/config
```

### EKS Cluster 정보 확인
```
kubectl cluster-info
```