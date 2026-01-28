variable "namespace" {
  type        = string
  description = "Namespace for Jenkins"
  default     = "jenkins"
}

variable "name" {
  type        = string
  description = "Helm release name"
  default     = "jenkins"
}

variable "chart_version" {
  type        = string
  description = "Jenkins Helm chart version"
  default     = "5.8.10"
}
