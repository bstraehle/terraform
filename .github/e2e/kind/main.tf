# CI-only root module: deploys modules/demo-apps to a kind cluster.
provider "kubernetes" {
  config_path = "~/.kube/config"
}

module "demo_apps" {
  source = "../../../modules/demo-apps"

  mvc_app_service_type = "ClusterIP"
}
