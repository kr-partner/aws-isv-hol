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

# 실습 가이드

## 1. 이벤트 엔진
가이드 문서 참고

## 2. Terraform을 활용한 EKS Cluster 생성

> 📌 디렉토리 구조
> 본 과정에서는 1번 워크스페이스를 사용합니다.
```bash
├── 0_contents
├── 1_eks-workspace
├── 2_vault-infra-workspace
├── 3_jenkins-infra-workspace
├── 4_argocd-workspace
├── 5_vso-infra-workspace
├── 6_vso-resource-workspace
└── README.md
```



### 1) [eks-workspace](./1_eks-workspace/)이동 후 EKS 클러스터 배포
Terraform CLI가 구성된 환경(로컬PC, VM 등)에서 `terraform` 명령을 수행하여 EKS 클러스터를 생성합니다.
```
terraform init
terraform plan
terraform apply --auto-approve
```

### 2) EKS Cluster 확인 
위 과정 수행 후 생성된 Bastion Host에 접속합니다.
```bash
ssh -i <SSH Key Pair> ec2-user@<Public IP>
```

### 3) EKS Cluster kubeconfig 설정
Bastion Host에서 `KUBECONFIG` 업데이트를 위해 `aws eks` 명령을 수행합니다.

```bash
aws eks --region $AWS_DEFAULT_REGION update-kubeconfig --name $CLUSTER_NAME --kubeconfig ~/.kube/config
```

### EKS Cluster 정보 확인
정상적으로 `kubectl` 명령이 동작하는지 확인합니다.
```bash
kubectl cluster-info
```

## 3. 실습환경 구성
EKS 클러스터에 실습을 위한 각종 환경을 구성합니다.

> 📌 디렉토리 구조  
> 본 과정부터는 2~6번 워크스페이스를 사용합니다.
```bash
├── 0_contents
├── 1_eks-workspace
├── 2_vault-infra-workspace
├── 3_jenkins-infra-workspace
├── 4_argocd-workspace
├── 5_vso-infra-workspace
├── 6_vso-resource-workspace
└── README.md
```