resource "random_string" "password" {
  length  = 16
  special = true
}

resource "random_string" "network_tag" {
  length  = 10
  upper   = false
  lower   = true
  number  = false
  special = false
}

# Node pool
resource "google_container_node_pool" "np" {
  name     = "${var.cluster_name}-np-${random_string.network_tag.result}"
  location = "${var.region}"
  project  = "${var.project}"
  cluster  = "${google_container_cluster.primary.name}"

  initial_node_count = "${var.min_node_count}"

  autoscaling {
    min_node_count = "${var.min_node_count}"
    max_node_count = "${var.max_node_count}"
  }

  management {
    auto_upgrade = true
  }

  node_config {
    machine_type = "${var.machine_type}"
    tags         = ["${random_string.network_tag.result}"]

    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/trace.append",
    ]
  }
}

# GKE cluster
resource "google_container_cluster" "primary" {
  name               = "${var.cluster_name}-${random_string.network_tag.result}"
  location           = "${var.region}"
  project            = "${var.project}"
  min_master_version = "${var.node_version}"
  node_version       = "${var.node_version}"
  enable_legacy_abac = false
  network            = "${google_compute_network.default.self_link}"
  subnetwork         = "${google_compute_subnetwork.default.self_link}"

  ip_allocation_policy {
    use_ip_aliases = true
  }

  private_cluster_config {
    enable_private_nodes   = true
    master_ipv4_cidr_block = "172.16.0.0/28"
  }

  master_authorized_networks_config {
    cidr_blocks = [{
      cidr_block = "${google_compute_instance.bastion.network_interface.0.access_config.0.nat_ip}/32"
    }]
  }

  lifecycle {
    ignore_changes = ["node_pool"]
  }

  node_pool {
    name = "default-pool"
  }

  master_auth {
    username = "admin"
    password = "${random_string.password.result}"
  }

  network_policy = {
    enabled = true
  }
}
