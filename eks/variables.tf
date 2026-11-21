variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "cluster_name" {
  description = "Name of the EKS cluster, also used for the VPC and tags"
  type        = string
  default     = "terraform-eks"
}

variable "kubernetes_version" {
  description = "EKS Kubernetes minor version; see https://docs.aws.amazon.com/eks/latest/userguide/kubernetes-versions.html"
  type        = string
  default     = "1.37"
}

variable "node_instance_types" {
  description = "EC2 instance types for the managed node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_count" {
  # The EKS module applies "desired" only when the node group is created and
  # ignores later changes, so scale an existing group by changing min/max or
  # with the AWS CLI or console.
  description = "Desired (at creation only), minimum, and maximum number of nodes"
  type = object({
    desired = number
    min     = number
    max     = number
  })
  default = {
    desired = 2
    min     = 1
    max     = 3
  }

  validation {
    condition     = var.node_count.min <= var.node_count.desired && var.node_count.desired <= var.node_count.max
    error_message = "node_count must satisfy min <= desired <= max."
  }
}

variable "api_allowed_cidrs" {
  description = "CIDR blocks allowed to reach the public EKS API endpoint, e.g. [\"203.0.113.10/32\"] for your workstation"
  type        = list(string)

  validation {
    condition     = length(var.api_allowed_cidrs) > 0 && alltrue([for c in var.api_allowed_cidrs : can(cidrhost(c, 0))])
    error_message = "api_allowed_cidrs must be a non-empty list of valid CIDR blocks."
  }

  validation {
    condition     = !anytrue([for c in var.api_allowed_cidrs : endswith(c, "/0")])
    error_message = "api_allowed_cidrs must not open the API endpoint to the whole internet (/0)."
  }
}
