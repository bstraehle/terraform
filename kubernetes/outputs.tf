output "namespace" {
  description = "Namespace of the apps"
  value       = module.demo_apps.namespace
}

output "mvc_app_url" {
  description = "URL of the MVC app's load balancer"
  value       = module.demo_apps.mvc_app_address == null ? null : "http://${module.demo_apps.mvc_app_address}:8000"
}
