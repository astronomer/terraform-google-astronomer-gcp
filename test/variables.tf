variable "region" {
  type = string
}

variable "project_id" {
  type = string
}

variable "deployment_id" {
  type = string
}

variable "zonal" {
  type    = bool
  default = false
}

variable "spotinist_token" {
  type    = string
  default = "12345"
}
