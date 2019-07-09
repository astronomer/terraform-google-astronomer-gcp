variable "deployment_id" {}

module "astronomer_gcp" {
  source           = "../.."
  deployment_id    = var.deployment_id
  dns_managed_zone = "steven-zone"
  project          = "astronomer-cloud-dev-236021"
  admin_emails     = ["steven@astronomer.io"]
}
