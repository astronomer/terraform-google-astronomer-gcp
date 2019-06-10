module "astronomer_gcp" {
  # source  = "astronomer/astronomer-gcp/google"
  # version = "<fill me in!>"
  # insert the 5 required variables here
  source = "../"
  deployment_id = "test"
  dns_managed_zone = "steven-zone"
  project = "astronomer-cloud-dev-236021"
  admin_emails = ["steven@astronomer.io"]
}
