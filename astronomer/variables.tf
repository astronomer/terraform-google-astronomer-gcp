variable "cluster_type" {
  default = "private"
  type    = "string"
}

variable "istio_helm_release_version" {
  default = "1.1.7"
  type    = "string"
}

variable "git_clone_from" {
  default = "https://github.com/astronomer/helm.astronomer.io.git"
  type    = "string"
}

variable "astronomer_version" {
  default = "v0.9.1-alpha.1"
  type    = "string"
}

variable "load_balancer_ip" {
  default = ""
  type    = "string"
}

variable "base_domain" {
  type = "string"
}

variable "astronomer_namespace" {
  default = "astronomer"
  type    = "string"
}

variable "admin_email" {
  description = "An email address"
  type        = "string"
}
