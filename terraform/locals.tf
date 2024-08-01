data "google_compute_zones" "available" {}

data "google_container_engine_versions" "gke" {
  location = local.region
}

data "google_compute_instance_group" "sample_instance_group" {
  self_link = var.enable_blue_platform_node_pool ? replace(google_container_node_pool.node_pool_platform[0].instance_group_urls[0], "instanceGroupManagers", "instanceGroups") : replace(google_container_node_pool.node_pool_platform_green[0].instance_group_urls[0], "instanceGroupManagers", "instanceGroups")
}

data "google_compute_instance" "sample_instance" {
  self_link = tolist(data.google_compute_instance_group.sample_instance_group.instances)[0]
}

locals {
  project                = data.google_compute_zones.available.project
  region                 = data.google_compute_zones.available.region
  zone                   = data.google_compute_zones.available.names[0]
  location               = var.zonal_cluster ? local.zone : local.region
  cluster_name           = google_container_cluster.primary.name
  endpoint               = google_container_cluster.primary.endpoint
  cluster_ca_certificate = google_container_cluster.primary.master_auth[0].cluster_ca_certificate
  bastion_name           = "${var.deployment_id}-bastion"
  # the second ternary is due to a bug during terraform destroy that the random_string.postgres_airflow_password
  # is an empty array and causes an error.  this just checks and lets it keep going through destroy successfully.
  postgres_airflow_password = (
    var.postgres_airflow_password == ""
    ? random_string.postgres_airflow_password != [] ? random_string.postgres_airflow_password[0].result : ""
    : var.postgres_airflow_password
  )

  db_engine = lower(split("_",var.db_version)[0])


  core_network_id = format(
    "projects/%s/global/networks/%s",
    google_compute_network.core.project,
    google_compute_network.core.name,
  )
  gke_subnetwork_id = format(
    "projects/%s/regions/%s/subnetworks/%s",
    google_compute_subnetwork.gke.project,
    google_compute_subnetwork.gke.region,
    google_compute_subnetwork.gke.name,
  )

  base_domain = var.dns_managed_zone != "" ? format(
    "%s.%s",
    var.deployment_id,
    substr(
      data.google_dns_managed_zone.public_zone[0].dns_name,
      0,
      length(data.google_dns_managed_zone.public_zone[0].dns_name) - 1,
    ),
  ) : ""

  # min_master_version = var.min_master_version == "" ? data.google_container_engine_versions.gke.latest_master_version : var.min_master_version
  # node_version = var.node_version == "" ? data.google_container_engine_versions.gke.latest_node_version : var.node_version

  gke_nodepool_network_tags = data.google_compute_instance.sample_instance.tags

  tls_key  = var.lets_encrypt ? tls_private_key.cert_private_key.0.private_key_pem : ""
  tls_cert = var.dns_managed_zone == "" ? "" : <<EOF
${acme_certificate.lets_encrypt[0].certificate_pem}
${acme_certificate.lets_encrypt[0].issuer_pem}
EOF
}
