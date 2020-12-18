variable "deployment_id" {}

variable "zonal" {
  default = false
}

module "astronomer_gcp" {
  source                     = "../.."
  deployment_id              = var.deployment_id
  dns_managed_zone           = "circleci-test-zone"
  email                      = "infrastructure@astronomer.io"
  zonal_cluster              = var.zonal
  management_endpoint        = "public"
  enable_gke_metered_billing = true
  db_max_connections         = 1000
}
