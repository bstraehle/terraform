variable "image_tag" {
  description = "Tag of the bstraehle/mvc-app and bstraehle/rest-api images"
  type        = string
  default     = "latest"
}

variable "mvc_app_allowed_cidrs" {
  description = "Client CIDRs allowed through the MVC app's load balancer; defaults to the eks workspace's api_allowed_cidrs"
  type        = list(string)
  default     = null
}
