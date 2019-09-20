# Node pool
resource "google_container_node_pool" "node_pool_mt" {

  provider = google-beta

  # theses can't be created or deleted at the same time.
  depends_on = [google_container_node_pool.node_pool_platform]
  version    = data.google_container_engine_versions.versions.latest_master_version

  name = "${var.deployment_id}-mt-${formatdate("MM-DD-hh-mm", timestamp())}"

  # this one can take a long time to delete or create
  timeouts {
    create = "30m"
    delete = "30m"
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [name]
  }

  location = var.zonal_cluster ? local.zone : local.region
  cluster  = google_container_cluster.primary.name

  # if we are 'regional' i.e. in 3 zones,
  # "1" here means "1 in each zone"
  initial_node_count = var.zonal_cluster ? "3" : "1"

  autoscaling {
    min_node_count = var.zonal_cluster ? "3" : "1"
    max_node_count = var.zonal_cluster ? var.max_node_count : ceil(var.max_node_count / 3)
  }

  management {
    # https://cloud.google.com/kubernetes-engine/docs/how-to/node-auto-upgrades
    auto_upgrade = true

    # https://cloud.google.com/kubernetes-engine/docs/how-to/node-auto-repair
    auto_repair = true
  }

  node_config {

    labels = {
      "astronomer.io/multi-tenant" = "true"
    }

    machine_type = var.machine_type

    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/trace.append",
    ]

    dynamic "taint" {
      for_each = var.mt_node_pool_taints
      content {
        effect = taint.value.effect
        key    = taint.value.key
        value  = taint.value.value
      }
    }

    # COS_CONTAINERD is required for sandbox_config to work
    image_type = var.enable_gvisor ? "COS_CONTAINERD" : "COS"

    # Only include sandbox config if we are using gvisor
    dynamic "sandbox_config" {
      for_each = var.enable_gvisor ? ["placeholder"] : []
      content {
        sandbox_type = "gvisor"
      }
    }

  }
}

resource "google_container_node_pool" "node_pool_platform" {

  provider = google-beta

  name    = "${var.deployment_id}-platform-${formatdate("MM-DD-hh-mm", timestamp())}"
  version = data.google_container_engine_versions.versions.latest_master_version

  location = var.zonal_cluster ? local.zone : local.region
  cluster  = google_container_cluster.primary.name

  # if we are 'regional' i.e. in 3 zones,
  # "1" here means "1 in each zone"
  initial_node_count = var.zonal_cluster ? "3" : "1"

  autoscaling {
    min_node_count = var.zonal_cluster ? "3" : "1"
    max_node_count = var.zonal_cluster ? var.max_node_count : ceil(var.max_node_count / 3)
  }

  management {
    # https://cloud.google.com/kubernetes-engine/docs/how-to/node-auto-upgrades
    auto_upgrade = true

    # https://cloud.google.com/kubernetes-engine/docs/how-to/node-auto-repair
    auto_repair = true
  }

  node_config {

    # Container-Optimized OS
    image_type = "COS"

    machine_type = var.machine_type_platform

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

    dynamic "taint" {
      for_each = var.platform_node_pool_taints
      content {
        effect = taint.value.effect
        key    = taint.value.key
        value  = taint.value.value
      }
    }
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [name]
  }
}
