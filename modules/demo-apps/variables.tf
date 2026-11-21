variable "namespace" {
  description = "Namespace to create for the apps"
  type        = string
  default     = "demo"
}

variable "image_tag" {
  description = "Tag of the bstraehle/mvc-app and bstraehle/rest-api images"
  type        = string
  default     = "latest"
}

variable "mvc_app_service_type" {
  description = "Service type for the MVC app: LoadBalancer on cloud clusters, ClusterIP for port-forwarding"
  type        = string
  default     = "LoadBalancer"

  validation {
    condition     = contains(["LoadBalancer", "NodePort", "ClusterIP"], var.mvc_app_service_type)
    error_message = "mvc_app_service_type must be LoadBalancer, NodePort, or ClusterIP."
  }
}

variable "mvc_app_service_annotations" {
  description = "Annotations for the MVC app's Service, e.g. cloud load balancer settings"
  type        = map(string)
  default     = {}
}

variable "mvc_app_allowed_cidrs" {
  description = "Client CIDRs allowed through the MVC app's load balancer; empty allows all"
  type        = list(string)
  default     = []
}
