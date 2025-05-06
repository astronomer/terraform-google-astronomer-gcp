data "http" "local_ip" {
  url = "https://api.ipify.org/"
}

module "astronomer_gcp" {
  source                     = "../terraform"
  deployment_id              = var.deployment_id
  dns_managed_zone           = "astrodev"
  email                      = "infrastructure@astronomer.io"
  zonal_cluster              = var.zonal
  management_endpoint        = "public"
  kube_api_whitelist_cidr    = ["${trimspace(data.http.local_ip.response_body)}/32"]
  enable_gke_metered_billing = true
  db_max_connections         = 1000
  db_version                 = "POSTGRES_14"
  db_deletion_protection     = false
  wait_for                   = 100
}
