variable "deployment_id" {}

variable "zonal" {
  default = true
}

module "astronomer_gcp" {
  source                     = "../.."
  deployment_id              = var.deployment_id
  dns_managed_zone           = "steven-zone"
  email                      = "steven@astronomer.io"
  zonal_cluster              = var.zonal
  management_endpoint        = "public"
  enable_gke_metered_billing = true
}
