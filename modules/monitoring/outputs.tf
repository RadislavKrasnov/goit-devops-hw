output "namespace" {
  value = var.namespace
}

output "grafana_service_name" {
  value = "${helm_release.kube_prometheus_stack.name}-grafana"
}
