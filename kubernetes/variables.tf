variable "image_tag" {
  description = "Tag of the bstraehle/mvc-app and bstraehle/rest-api images"
  type        = string
  default     = "latest"
}

variable "replicas" {
  description = "Replicas per app"
  type        = number
  default     = 2
}
