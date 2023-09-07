variable "eks_cluster_name" {
  default = "eks_cluster"
}

variable "eks_cluster_node_group_name" {
  default = "eks_cluster-nodegroup"
}

variable "eks_cluster_version" {
  default = "1.24"
}

variable "ec2_key_pair" {
  # default = "study-aws"
  # default = "ee-default-keypair"
  default = "hw-key"
}

variable "worker_node_instance_type" {
  default = ["t3.medium"]
}

variable "worker_node_min_size" {
  default = 2
}

variable "worker_node_max_size" {
  default = 5
}

variable "worker_node_desired_size" {
  default = 2
}

variable "aws_region" {
  # default = "ap-northeast-2"
  default = "us-east-1"
}

variable "var_vpc_cidr" {
  default = "192.168.0.0/16"
}

variable "var_subnet_1_az" {
  # default = "ap-northeast-2a"
  default = "us-east-1a"
}

variable "var_subnet_2_az" {
  # default = "ap-northeast-2c"
  default = "us-east-1c"
}

variable "var_subnet_private_1_cidr" {
  default = "192.168.1.0/24"
}

variable "var_subnet_private_2_cidr" {
  default = "192.168.2.0/24"
}

variable "var_subnet_public_1_cidr" {
  default = "192.168.10.0/24"
}

variable "var_subnet_public_2_cidr" {
  default = "192.168.11.0/24"
}

variable "AWS_ACCESS_KEY_ID" {
  default = ""
}

variable "AWS_SECRET_ACCESS_KEY" {
  default = ""
}

variable "AWS_SESSION_TOKEN" {
  default = ""
}
