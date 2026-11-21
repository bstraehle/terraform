# Plan-only tests with a mocked provider; run with: terraform test
mock_provider "kubernetes" {}

run "defaults" {
  command = plan

  assert {
    condition     = kubernetes_namespace_v1.demo.metadata[0].labels["pod-security.kubernetes.io/enforce"] == "restricted"
    error_message = "The namespace must enforce the restricted Pod Security Standard."
  }

  assert {
    condition = alltrue([
      for d in kubernetes_deployment_v1.app :
      d.spec[0].template[0].spec[0].container[0].port[0].container_port == 8080
    ])
    error_message = "Containers must expose port 8080, where the .NET images listen."
  }

  assert {
    # The provider sends false for an unset container-level run_as_non_root,
    # overriding the pod-level setting and violating the restricted profile.
    condition = alltrue([
      for d in kubernetes_deployment_v1.app :
      d.spec[0].template[0].spec[0].container[0].security_context[0].run_as_non_root
    ])
    error_message = "Containers must set run_as_non_root = true explicitly."
  }

  assert {
    condition = alltrue([
      for d in kubernetes_deployment_v1.app :
      d.spec[0].template[0].spec[0].container[0].security_context[0].read_only_root_filesystem &&
      !d.spec[0].template[0].spec[0].container[0].security_context[0].allow_privilege_escalation
    ])
    error_message = "Containers must use a read-only root filesystem without privilege escalation."
  }

  assert {
    condition     = kubernetes_deployment_v1.app["mvc-app"].spec[0].template[0].spec[0].container[0].env[0].value == "http://rest-api-service:8001"
    error_message = "The MVC app must call the API through rest-api-service."
  }

  assert {
    condition     = kubernetes_service_v1.app["mvc-app"].spec[0].type == "LoadBalancer" && kubernetes_service_v1.app["rest-api"].spec[0].type == "ClusterIP"
    error_message = "Only the MVC app should be exposed through a load balancer."
  }
}

run "single_replica_and_load_balancer_settings" {
  command = plan

  variables {
    mvc_app_allowed_cidrs       = ["203.0.113.10/32"]
    mvc_app_service_annotations = { "example.com/annotation" = "true" }
  }

  assert {
    # Both apps keep per-pod state (in-memory records, antiforgery keys).
    condition     = alltrue([for d in kubernetes_deployment_v1.app : d.spec[0].replicas == "1"])
    error_message = "Both apps must run a single replica."
  }

  assert {
    condition     = kubernetes_service_v1.app["mvc-app"].spec[0].load_balancer_source_ranges == toset(["203.0.113.10/32"])
    error_message = "The MVC load balancer must only allow mvc_app_allowed_cidrs."
  }

  assert {
    condition     = kubernetes_service_v1.app["mvc-app"].metadata[0].annotations["example.com/annotation"] == "true" && length(kubernetes_service_v1.app["rest-api"].metadata[0].annotations) == 0
    error_message = "Service annotations must only apply to the MVC app."
  }
}

run "rejects_invalid_service_type" {
  command = plan

  variables {
    mvc_app_service_type = "ExternalName"
  }

  expect_failures = [var.mvc_app_service_type]
}
