variable "namespace" {
  type        = string
  description = "Namespace for Argo CD"
  default     = "argocd"
}

variable "name" {
  type        = string
  description = "Helm release name"
  default     = "argo-cd"
}

variable "chart_version" {
  type        = string
  description = "Argo CD Helm chart version"
  default     = "5.46.4"
}
