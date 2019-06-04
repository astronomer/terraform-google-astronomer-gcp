resource "random_string" "password" {
  length  = 16
  special = true
}

# GKE cluster
resource "google_container_cluster" "primary" {
  provider = "google-beta"
  name     = "${var.deployment_id}-cluster"

  # "
  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  # "
  # quote from:
  # https://www.terraform.io/docs/providers/google/r/container_cluster.html#node_pool
  remove_default_node_pool = true

  initial_node_count = 1

  # "If you specify a region (such as us-west1), the cluster will be a regional cluster"
  # quoted from:
  # https://www.terraform.io/docs/providers/google/r/container_cluster.html#node_pool
  location = "${var.region}"

  min_master_version = "${var.min_master_version}"
  node_version       = "${var.node_version}"
  network            = "${local.core_network_id}"
  subnetwork         = "${local.gke_subnetwork_id}"

  enable_legacy_abac = false

  ip_allocation_policy {
    use_ip_aliases                = true
    cluster_secondary_range_name  = "${google_compute_subnetwork.gke.secondary_ip_range.0.range_name}"
    services_secondary_range_name = "${google_compute_subnetwork.gke.secondary_ip_range.1.range_name}"
  }

  private_cluster_config {
    enable_private_endpoint = true
    enable_private_nodes    = true
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }

  master_authorized_networks_config {
    cidr_blocks {
      display_name = "${google_compute_subnetwork.bastion.name}"
      cidr_block   = "${google_compute_subnetwork.bastion.ip_cidr_range}"
    }
  }

  node_locations = [
    "${var.region}-a",
    "${var.region}-b",
    "${var.region}-c",
  ]

  /*
  # TODO: use certificate auth
  # after this issue is resolved

  # There is a known issue with issue_client_certificate = true
  # where on the first run, it will issue the cert, then will set
  # it to 'false'. So, when we run again, terraform thinks we should
  # tear down the cluster, which we don't want. This is a work around.
  # Applicable to Kubernetes 1.12
  # https://github.com/terraform-providers/terraform-provider-google/issues/3369
  lifecycle {
    ignore_changes = ["master_auth"]
  }

  # Setting an empty username and password explicitly disables basic auth
  master_auth {
    username = ""
    password = ""

    client_certificate_config {
      issue_client_certificate = true
    }
  }
  */

  master_auth {
    username = "admin"
    password = "${random_string.password.result}"

    client_certificate_config {
      issue_client_certificate = false
    }
  }
  network_policy = {
    enabled = true
  }
}
