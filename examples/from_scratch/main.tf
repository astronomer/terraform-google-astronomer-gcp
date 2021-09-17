variable "deployment_id" {}

variable "zonal" {
  default = false
}

variable "spotinist_token" {
  default = "12345"
}

module "astronomer_gcp" {
  source                     = "../.."
  deployment_id              = var.deployment_id
  dns_managed_zone           = "steven-zone"
  email                      = "steven@astronomer.io"
  zonal_cluster              = var.zonal
  management_endpoint        = "public"
  enable_gke_metered_billing = true
  db_max_connections         = 1000
  db_version                 = "POSTGRES_12"
}
