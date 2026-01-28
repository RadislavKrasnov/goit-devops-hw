resource "kubernetes_namespace_v1" "jenkins" {
  metadata {
    name = var.namespace
  }
}


resource "kubernetes_service_account_v1" "jenkins_sa" {
  metadata {
    name      = "jenkins-sa"
    namespace = var.namespace
  }
}

resource "kubernetes_cluster_role_binding_v1" "jenkins_sa_admin" {
  metadata {
    name = "jenkins-sa-cluster-admin"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.jenkins_sa.metadata[0].name
    namespace = var.namespace
  }
}

resource "helm_release" "jenkins" {
  name             = var.name
  namespace        = var.namespace
  repository       = "https://charts.jenkins.io"
  chart            = "jenkins"
  version          = var.chart_version
  create_namespace = false

  values = [
    file("${path.module}/values.yaml")
  ]

  depends_on = [
    kubernetes_namespace_v1.jenkins,
    kubernetes_cluster_role_binding_v1.jenkins_sa_admin
  ]
}
