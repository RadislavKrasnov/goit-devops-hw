output "argo_cd_server_service" {
  value       = "argocd-server.${var.namespace}.svc.cluster.local"
  description = "Internal Argo CD server service name"
}

output "admin_password_hint" {
  value       = "kubectl -n ${var.namespace} get secret argocd-initial-admin-secret -o jsonpath=\"{.data.password}\" | base64 -d"
  description = "How to get initial admin password"
}
