variable "cluster_type" {
  default = "private"
  type    = "string"
}

variable "git_clone_from" {
  default = "https://github.com/astronomer/helm.astronomer.io.git"
  type = "string"
}

variable "astronomer_version" {
  default = "master"
  type = "string"
}

variable "base_domain" {
  # TODO
  default = "astro.steven-development.com"
  type = "string"
}

variable "namespace_uid" {
  type = "string"
}
