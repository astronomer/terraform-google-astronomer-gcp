data "google_compute_zones" "available" {}

data "google_container_engine_versions" "gke" {
  location = local.region
}

locals {
  project    = data.google_compute_zones.available.project
  region     = data.google_compute_zones.available.region
  zone       = data.google_compute_zones.available.names[0]
  kubeconfig = <<EOF
apiVersion: v1
clusters:
- cluster:
    server: https://${google_container_cluster.primary.endpoint}
    certificate-authority-data: ${google_container_cluster.primary.master_auth[0].cluster_ca_certificate}
  name: cluster
contexts:
- context:
    cluster: cluster
    user: admin
  name: context
current-context: "context"
kind: Config
preferences: {}
users:
- name: "${google_container_cluster.primary.master_auth[0].username}"
  user:
    password: "${google_container_cluster.primary.master_auth[0].password}"
    username: "${google_container_cluster.primary.master_auth[0].username}"

  EOF
  bastion_name = "${var.deployment_id}-bastion"
  postgres_airflow_password = var.postgres_airflow_password == "" ? random_string.postgres_airflow_password[0].result : var.postgres_airflow_password
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
  base_domain = format(
    "%s.%s",
    var.deployment_id,
    substr(
      data.google_dns_managed_zone.public_zone[0].dns_name,
      0,
      length(data.google_dns_managed_zone.public_zone[0].dns_name) - 1,
    ),
  )
  # min_master_version = var.min_master_version == "" ? data.google_container_engine_versions.gke.latest_master_version : var.min_master_version
  # node_version = var.node_version == "" ? data.google_container_engine_versions.gke.latest_node_version : var.node_version
}

