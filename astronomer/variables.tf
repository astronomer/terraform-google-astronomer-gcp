variable "cluster_type" {
  default = "private"
  type    = "string"
}

variable "git_clone_from" {
  default = "https://github.com/astronomer/helm.astronomer.io.git"
  type    = "string"
}

variable "astronomer_version" {
  default = "v0.8.2"
  type    = "string"
}

variable "base_domain" {
  type = "string"
}

variable "admin_email" {
  description = "An email address"
  type        = "string"
}
