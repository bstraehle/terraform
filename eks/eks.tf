module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.29.0"

  name               = var.cluster_name
  kubernetes_version = var.kubernetes_version

  # Public API endpoint so kubectl and the kubernetes workspace can reach the
  # cluster from your machine, limited to the CIDRs you allow.
  endpoint_public_access       = true
  endpoint_public_access_cidrs = var.api_allowed_cidrs

  # Grant the identity running Terraform cluster admin via an EKS access entry.
  enable_cluster_creator_admin_permissions = true

  addons = {
    coredns = {}
    eks-pod-identity-agent = {
      before_compute = true
    }
    kube-proxy = {}
    vpc-cni = {
      before_compute = true
    }
  }

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    default = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = var.node_instance_types

      desired_size = var.node_count.desired
      min_size     = var.node_count.min
      max_size     = var.node_count.max
    }
  }
}
