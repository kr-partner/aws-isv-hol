resource "helm_release" "jenkins" {
  namespace        = kubernetes_namespace.jenkins.metadata[0].name
  name             = "jenkins"
  create_namespace = false
  wait             = true
  wait_for_jobs    = true

  repository = "https://charts.jenkins.io"
  chart      = "jenkins"

  set {
    name  = "controller.serviceType"
    value = "LoadBalancer"
  }
  set {
    name  = "controller.serviceAnnotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-type"
    value = "nlb"
  }
  set {
    name  = "controller.serviceAnnotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-scheme"
    value = "internet-facing"
  }
  set {
    name  = "controller.numExecutors"
    value = "1"
  }
}

resource "kubernetes_namespace" "jenkins" {
  metadata {
    name = "jenkins"
  }
}

data "kubernetes_service" "jenkins" {
  metadata {
    name      = "jenkins"
    namespace = "jenkins"
  }
  # K8s Service Resource가 생성된 이후에 External IP를 얻을 수 있기 때문에 명시적 의존성 부여
  depends_on = [helm_release.jenkins]
}

data "kubernetes_secret" "jenkins" {
  metadata {
    namespace = "jenkins"
    name      = "jenkins"
  }
  depends_on = [helm_release.jenkins]
}