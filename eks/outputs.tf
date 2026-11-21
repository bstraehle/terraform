output "region" {
  description = "AWS region"
  value       = var.region
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for the EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group attached to the EKS control plane"
  value       = module.eks.cluster_security_group_id
}

output "api_allowed_cidrs" {
  description = "CIDRs allowed to reach the EKS API; the kubernetes workspace reuses them for the MVC app's load balancer"
  value       = var.api_allowed_cidrs
}

output "configure_kubectl" {
  description = "Command to add the cluster to your kubeconfig"
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${module.eks.cluster_name}"
}
