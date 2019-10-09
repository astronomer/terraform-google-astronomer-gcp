resource "random_string" "password" {
  length  = 16
  special = true
}

data "http" "local_ip" {
  url = "http://ipv4.icanhazip.com/s"
}

# data "google_container_engine_versions" "versions" {
#   location       = var.zonal_cluster ? local.zone : local.region
#   version_prefix = "1.14."
# }

# GKE cluster
resource "google_container_cluster" "primary" {
  provider = google-beta
  name     = "${var.deployment_id}-cluster"

  # "
  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  # "
  # quote from:
  # https://www.terraform.io/docs/providers/google/r/container_cluster.html#node_pool
  remove_default_node_pool = true

  maintenance_policy {
    daily_maintenance_window {
      # 9am EST
      # For maintenance windows in general,
      # people usually choose a time of least-use.
      # The nature of Airflow is such that the jobs
      # are likely to run in those same windows, so
      # it's best to just choose a time where support
      # will likely be available.
      start_time = "13:00"
    }
  }

  # This only applies to the default node pool, which we will delete
  initial_node_count = 1

  # "If you specify a region (such as us-west1), the cluster will be a regional cluster"
  # quoted from:
  # https://www.terraform.io/docs/providers/google/r/container_cluster.html#node_pool
  location = var.zonal_cluster ? local.zone : local.region

  min_master_version = var.kube_version_gke

  network    = local.core_network_id
  subnetwork = local.gke_subnetwork_id

  enable_legacy_abac = false

  ip_allocation_policy {
    use_ip_aliases                = true
    cluster_secondary_range_name  = google_compute_subnetwork.gke.secondary_ip_range[0].range_name
    services_secondary_range_name = google_compute_subnetwork.gke.secondary_ip_range[1].range_name
  }

  private_cluster_config {
    enable_private_endpoint = var.management_endpoint == "public" ? false : true
    enable_private_nodes    = true
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }

  master_authorized_networks_config {
    cidr_blocks {
      # display_name = google_compute_subnetwork.bastion.name
      # either whitelist the caller's IP or only allow access from bastion
      cidr_block = var.management_endpoint == "public" ? "${trimspace(data.http.local_ip.body)}/32" : google_compute_subnetwork.bastion[0].ip_cidr_range
    }
  }

  /*
  node_locations = var.zonal_cluster ? [local.zone] : ["${local.region}-a",
    "${local.region}-b",
  "${local.region}-c"]
  */

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
    password = random_string.password.result

    client_certificate_config {
      issue_client_certificate = false
    }
  }
  network_policy {
    enabled  = true
    provider = "CALICO"
  }

}

resource "random_id" "kubeconfig_suffix" {
  byte_length = 4
}

resource "local_file" "kubeconfig" {
  sensitive_content = local.kubeconfig
  filename          = "./kubeconfig-${random_id.kubeconfig_suffix.hex}"
}
