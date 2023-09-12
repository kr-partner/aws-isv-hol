# EKS에서 Helm을 이용한 Jenkins 배포
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