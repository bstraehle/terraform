# Reads the cluster created by the eks workspace from its local state.
data "terraform_remote_state" "eks" {
  backend = "local"

  config = {
    path = "${path.module}/../eks/terraform.tfstate"
  }
}

provider "aws" {
  region = data.terraform_remote_state.eks.outputs.region
}

data "aws_eks_cluster" "this" {
  name = data.terraform_remote_state.eks.outputs.cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks", "get-token",
      "--cluster-name", data.aws_eks_cluster.this.name,
      "--region", data.terraform_remote_state.eks.outputs.region,
    ]
  }
}

module "demo_apps" {
  source = "../modules/demo-apps"

  image_tag = var.image_tag

  # The demo apps have no authentication or TLS, so only allow the same
  # clients as the EKS API endpoint by default.
  mvc_app_allowed_cidrs = var.mvc_app_allowed_cidrs != null ? var.mvc_app_allowed_cidrs : data.terraform_remote_state.eks.outputs.api_allowed_cidrs

  mvc_app_service_annotations = {
    # The Classic Load Balancer spans all three public subnets, but nodes may
    # run in only two zones; route across zones so no zone is left without
    # a backend.
    "service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled" = "true"
  }
}
