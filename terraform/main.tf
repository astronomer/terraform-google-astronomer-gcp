resource "random_string" "password" {
  length  = 16
  special = true
}

# data "google_container_engine_versions" "versions" {
#   location       = var.zonal_cluster ? local.zone : local.region
#   version_prefix = "1.14."
# }

# GKE cluster
resource "google_container_cluster" "primary" {
  provider = google-beta
  name     = "${var.deployment_id}-cluster"

  project               = data.google_project.project.project_id
  enable_shielded_nodes = var.gke_enable_shielded_nodes

  # "
  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  # "
  # quote from:
  # https://www.terraform.io/docs/providers/google/r/container_cluster.html#node_pool
  remove_default_node_pool = true

  release_channel {
    channel = var.gke_release_channel
  }

  maintenance_policy {

    dynamic "recurring_window" {
      for_each = var.recurring_window
      content {
        start_time = recurring_window.value.start_time
        end_time   = recurring_window.value.end_time
        recurrence = recurring_window.value.recurrence
      }
    }

    dynamic "daily_maintenance_window" {
      for_each = var.daily_maintenance_window
      content {
        start_time = daily_maintenance_window.value.start_time
      }
    }

    dynamic "maintenance_exclusion" {
      for_each = var.maintenance_exclusion
      content {
        start_time     = maintenance_exclusion.value.start_time
        end_time       = maintenance_exclusion.value.end_time
        exclusion_name = maintenance_exclusion.value.exclusion_name

        dynamic "exclusion_options" {
          for_each = maintenance_exclusion.value.exclusion_options
          content {
            scope = exclusion_options.value.scope
          }
        }
      }
    }

  }

  # This only applies to the default node pool, which we will delete
  initial_node_count = 1

  # "If you specify a region (such as us-west1), the cluster will be a regional cluster"
  # quoted from:
  # https://www.terraform.io/docs/providers/google/r/container_cluster.html#node_pool
  location = local.location

  min_master_version = var.kube_version_gke

  network    = local.core_network_id
  subnetwork = local.gke_subnetwork_id

  enable_legacy_abac = false

  ip_allocation_policy {
    cluster_secondary_range_name  = google_compute_subnetwork.gke.secondary_ip_range[0].range_name
    services_secondary_range_name = google_compute_subnetwork.gke.secondary_ip_range[1].range_name
  }

  private_cluster_config {
    enable_private_endpoint = var.management_endpoint == "public" ? false : true
    enable_private_nodes    = true
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }

  master_authorized_networks_config {
    dynamic "cidr_blocks" {
      for_each = var.management_endpoint == "public" ? var.kube_api_whitelist_cidr : toset([google_compute_subnetwork.bastion[0].ip_cidr_range])
      content {
        # display_name = google_compute_subnetwork.bastion.name
        # either whitelist the caller's IP or only allow access from bastion
        cidr_block = cidr_blocks.key
      }
    }
  }

  pod_security_policy_config {
    enabled = var.pod_security_policy_enabled
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
    client_certificate_config {
      issue_client_certificate = false
    }
  }
  network_policy {
    enabled  = var.enable_dataplane_v2 ? false : true
    provider = var.enable_dataplane_v2 ? "PROVIDER_UNSPECIFIED" : "CALICO"
  }

  # Setting dataplane v2 for GKE
  datapath_provider = var.enable_dataplane_v2 ? "ADVANCED_DATAPATH" : "LEGACY_DATAPATH"

  dynamic "resource_usage_export_config" {
    for_each = var.enable_gke_metered_billing ? ["placeholder"] : []
    content {
      enable_network_egress_metering = true

      bigquery_destination {
        dataset_id = google_bigquery_dataset.gke_metered_billing[0].dataset_id
      }
    }
  }
}

resource "random_id" "kubeconfig_suffix" {
  byte_length = 4
}

resource "google_bigquery_dataset" "gke_metered_billing" {
  count                      = var.enable_gke_metered_billing ? 1 : 0
  dataset_id                 = "${var.deployment_id}_gke_usage_metering_dataset"
  location                   = "US"
  delete_contents_on_destroy = true
}
