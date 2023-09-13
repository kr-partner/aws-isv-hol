terraform {
  cloud {
    # 참석자의 조직명 기입
    organization = "hyungwook"

    workspaces {
      # 참석자의 워크스페이스명 기입
      name = "aws-isv-hol"
    }
  }
}

provider "aws" {
  region  = var.aws_region
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.eks_cluster.token
  }
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.eks_cluster.token
}