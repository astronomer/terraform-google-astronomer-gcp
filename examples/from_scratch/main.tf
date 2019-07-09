variable "deployment_id" {}

module "astronomer_gcp" {
  source           = "../.."
  deployment_id    = var.deployment_id
  dns_managed_zone = "steven-zone"
  email            = "steven@astronomer.io"
  zonal_cluster    = true
}
