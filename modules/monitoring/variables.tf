variable "namespace" {
  type    = string
  default = "monitoring"
}

variable "release_name" {
  type    = string
  default = "kube-prom-stack"
}

variable "chart_version" {
  type    = string
  default = "81.4.2"
}
