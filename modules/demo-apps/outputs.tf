output "namespace" {
  description = "Namespace of the apps"
  value       = kubernetes_namespace_v1.demo.metadata[0].name
}

output "mvc_app_address" {
  description = "Load balancer hostname or IP of the MVC app, if its Service is a LoadBalancer"
  value = try(
    coalesce(
      kubernetes_service_v1.app["mvc-app"].status[0].load_balancer[0].ingress[0].hostname,
      kubernetes_service_v1.app["mvc-app"].status[0].load_balancer[0].ingress[0].ip,
    ),
    null,
  )
}
