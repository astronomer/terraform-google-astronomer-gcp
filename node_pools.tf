# Node pool
resource "google_container_node_pool" "node_pool_mt" {

  provider = google-beta

  name = "${var.deployment_id}-node-pool-multi-tenant"

  # this one can take a long time to delete or create
  timeouts {
    create = "30m"
    delete = "30m"
  }

  lifecycle {
    # ignore_changes =["node_config[0].labels", "node_config[0].taint"]
    ignore_changes =["node_config"]
  }

  location = var.region
  cluster  = google_container_cluster.primary.name

  # since we are 'regional' i.e. in 3 zones,
  # "1" here means "1 in each zone"
  initial_node_count = "1"

  autoscaling {
    min_node_count = "1"
    max_node_count = ceil(var.max_node_count / 3)
  }

  management {
    # https://cloud.google.com/kubernetes-engine/docs/how-to/node-auto-upgrades
    auto_upgrade = true

    # https://cloud.google.com/kubernetes-engine/docs/how-to/node-auto-repair
    auto_repair = true
  }

  node_config {

    machine_type = var.machine_type

    labels = {
      # One of the pools should have the label indicating that it's
      # multi-tenant, and the other should not.
      "astronomer.io/multi-tenant" = "true"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/trace.append",
    ]

    # this is required for sandbox_config to work
    image_type = "cos_containerd"

    sandbox_config {
      sandbox_type = "gvisor"
    }
  }
}

resource "google_container_node_pool" "node_pool_platform" {

  name = "${var.deployment_id}-node-pool-platform"

  location = var.region
  cluster  = google_container_cluster.primary.name

  # since we are 'regional' i.e. in 3 zones,
  # "1" here means "1 in each zone"
  initial_node_count = "1"

  autoscaling {
    min_node_count = "0"
    max_node_count = ceil(var.max_node_count / 3)
  }

  management {
    # https://cloud.google.com/kubernetes-engine/docs/how-to/node-auto-upgrades
    auto_upgrade = true

    # https://cloud.google.com/kubernetes-engine/docs/how-to/node-auto-repair
    auto_repair = true
  }

  node_config {
    machine_type = var.machine_type

    labels = {
      "astronomer.io/multi-tenant" = "false"
    }

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
