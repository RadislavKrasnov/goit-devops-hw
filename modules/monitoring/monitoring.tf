resource "kubernetes_namespace_v1" "monitoring" {
  metadata { name = var.namespace }
}

resource "helm_release" "kube_prometheus_stack" {
  name       = var.release_name
  namespace  = var.namespace
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = var.chart_version

  create_namespace = false

  values = [
    yamlencode({
      grafana = {
        service = { type = "ClusterIP" }
      }
      prometheus = {
        prometheusSpec = {
          retention = "12h"
        }
      }
    })
  ]

  depends_on = [kubernetes_namespace_v1.monitoring]
}
