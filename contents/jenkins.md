<img width="281" alt="image" src="https://github.com/kr-partner/aws-isv-hol/assets/128347806/bd67b4ce-2cc3-40cc-a97d-9442395dd565"><img width="467" alt="image" src="https://github.com/kr-partner/aws-isv-hol/assets/128347806/0304c9c3-4922-43fa-84b3-6f2d927076bc"># EKS에서 Helm을 이용한 Jenkins 배포
​
## 1.Jenkins 배포

### 1) Namespace 생성
```bash
$ kubectl create namespace jenkins
```
​
### 2) Helm Repo 추가
```bash
$ helm repo add jenkinsci https://charts.jenkins.io
```
​
### 3) Helm Deploy
- `jenkins-value.yaml` 작성
```bash
# jenkins-value.yaml, subnet은 eks가 배포된 public subnet 지정
---
controller:
  serviceType: LoadBalancer
  serviceAnnotations:
      service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
      service.beta.kubernetes.io/aws-load-balancer-scheme: "internet-facing"
```

- Helm Install
```bash
$ helm install jenkins -n jenkins -f jenkins-values.yaml jenkinsci/jenkins
---
# (중략)
NOTE: Consider using a custom image with pre-installed plugins
```      
​
### 4) Jenkins UI 확인
```bash
$ kubectl exec --namespace jenkins -it svc/jenkins -c jenkins -- /bin/cat /run/secrets/additional/chart-admin-password && echo
WZUeBvR78OD0YkCDL6fI9a #앞에 패스워드는 예시로 다음과 같이 출력됨

$ kubectl get svc jenkins -n jenkins
NAME      TYPE           CLUSTER-IP      EXTERNAL-IP                                                                        PORT(S)          AGE
jenkins   LoadBalancer   10.100.206.95   k8s-jenkins-jenkins-a378de12d6-21a1d91e9b00ed33.elb.ap-northeast-2.amazonaws.com   8080:32758/TCP   12m
```



> Jenkins 접속화면
> 
![Jenkins UI](https://raw.githubusercontent.com/hyungwook0221/img/main/uPic/eznO7z.jpg)



## 2. Vault 설정

### 1) KV *Secrets Engine*

```bash
# KV Secrets Engine 활성화
$ vault secrets enable kv-v2
...
Success! Enabled the kv-v2 secrets engine at: kv-v2/

# Secrets 등록
$ vault kv put kv-v2/aws/s3 object-url=https://songpubket.s3.ap-northeast-2.amazonaws.com/afc6a48cf93e78e27c2f0fd68ab59eb2.png
...
==== Secret Path ====
kv-v2/data/aws/random
…


# Secrets 확인
$ vault kv get kv-v2/aws/s3
...
===== Data =====
Key       Value
---       ----
…
```

### 2) Userpass *Auth Method*

```bash
# 정책(Policy) 등록
$ vault policy write jenkinscreds -<<EOF
path "kv-v2/*" {
  capabilities = ["read", "list"]
}
path "aws/sts/federation" {
  capabilities = ["read"]
}
EOF
...
Success! Uploaded policy: jenkinscreds


# Userpass 인증 활성화 및 사용자(User) 등록
$ vault auth enable userpass
...
Success! Enabled userpass auth method at: userpass/

$ vault write auth/userpass/users/jenkins password=jenkinspwd policies=jenkinscreds
...
Success! Data written to: auth/userpass/users/jenkins


# 로그인 (Token 회수)
$ vault login -method=userpass username=jenkins password=jenkinspwd
...
token                  hvs…..
```


## 3. Jenkins 기본 설정
### 1) Plugins 설치
Jenkins 관리 -> *System Configuration*의 Plugins -> Available plugins -> HashiCorp Vault 설치

### 2) Credentials 등록
Jenkins 관리 -> *Security*의 Credentials -> (global) 클릭 -> Add Credentials -> Kind는  'Token Credentials'로 선택 & Token에는 상단에서 로그인 후, 회수한 Token 입력

### 3) Pipeline 생성
+새로운 Item -> Pipeline 선택 -> Pipeline 입력
```
def configuration = [vaultUrl: 'http://<Vault 주소>:8200',  vaultCredentialId: ‘<Credential 등록한 ID값>', engineVersion: 2]
def secrets = [
  [path: 'kv-v2/aws/s3', engineVersion:2, secretValues: [
    [envVar: 'url', vaultKey: 'object-url']
  ]]
]

pipeline {
    agent any
    stages {
 stage('Vault') {
            steps {
                withVault([configuration: configuration, vaultSecrets: secrets]) {
	sh "curl -I ${env.url}"
                }
            }
        }
    }
}
```

## 4. Jenkins '지금 빌드'
KV Engine에서 읽어온 값에 curl을 날린 값과 Console에 동일한 파일이 찍히는 것을 확인할 수 있다.


## 5. 추가 실습
### 1) Vault AWS *Secrets Engine*
```
# AWS Secrets Engine 활성화
$ vault secrets enable aws
...
Success! Enabled the aws secrets engine at: aws/

# Credentials 발급 권한을 가진 IAM User로 ROOT 설정
$ vault write aws/config/root \ 
  access_key=… \ 
  secret_key=… \ 
  region=ap-northeast-2
Success! Data written to: aws/config/root

# Federation Token 설정
$ vault write aws/roles/awsrole \
 credential_type=federation_token \
 policy_document=-<<EOF
 { 
   "Version": "2012-10-17", 
   "Statement": [ 
     {
        "Effect": "Allow", 
        "Action": "ec2:*", 
        "Resource": "*" 
     } 
  ] 
}
 EOF
...
Success! Data written to: aws/roles/awsrole
…
```

### 2) Jenkins Pipeline
```
pipeline {
    agent any
    environment {
        VAULT_HOST = ‘<Vault 주소>'
        VAULT_PORT = '8200'
    }
    stages {
        stage('AWS') {
            steps {
                withCredentials([string(credentialsId: ‘<Credential 등록한 ID값> ', variable: 'TOKEN')]) {
                    sh '''
                    curl -H "X-Vault-Token: ${TOKEN}＂      http://${VAULT_HOST}:${VAULT_PORT}/v1/aws/sts/awsrole > aws-access.json
                    export AWS_ACCESS_KEY_ID=$(jq -r '.data.access_key' ./aws-access.json)
                    '''
                }
            }
        }
    }
}
```



## 6. Jenkins '지금 빌드'
AWS Secrets Engine에서 읽어온 값을 확인할 수 있다. 추가적인 Command(export)를 작성한 경우 Credential이 Console에 노출된 것을 확인할 수 있다.

















