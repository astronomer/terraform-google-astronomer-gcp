# The data source is necessary to get the current
# master kube version instead of the previous version
data "google_container_cluster" "primary" {
  depends_on = [google_container_cluster.primary]
  name       = google_container_cluster.primary.name
  location   = google_container_cluster.primary.location
}

# Node pool
resource "google_container_node_pool" "node_pool_mt" {

  provider = google-beta

  # these can't be created or deleted at the same time.
  depends_on = [google_container_node_pool.node_pool_platform]
  # version    = data.google_container_cluster.primary.master_version
  version = var.kube_version_gke

  # We want the multi-tenant node pool to be completely replaced
  # instead of rolling deployment.
  # The master_version will ensure that the node pool is created then
  # destroyed if there is an update.
  name = "${var.deployment_id}-mt-${formatdate("MM-DD-hh-mm", timestamp())}"

  # this one can take a long time to delete or create
  timeouts {
    create = "30m"
    update = "30m"
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
    min_node_count = "0"
    max_node_count = var.zonal_cluster ? var.max_node_count : ceil(var.max_node_count / 3)
  }

  management {
    # https://cloud.google.com/kubernetes-engine/docs/how-to/node-auto-upgrades
    # With this set to false, then an update will only occur when terraform runs
    # because we set the node pool kubelet version to the version of the master,
    # which will trigger an update, and the name including a timestamp will
    # force a create then destroy event.
    auto_upgrade = false

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

resource "google_container_node_pool" "node_pool_dynamic_pods" {
  count = var.create_dynamic_pods_nodepool ? 1 : 0

  provider = google-beta

  # these can't be created or deleted at the same time.
  depends_on = [google_container_node_pool.node_pool_mt]
  # version    = data.google_container_cluster.primary.master_version

  # this one can take a long time to delete or create
  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }

  lifecycle {
    create_before_destroy = true
  }

  location = var.zonal_cluster ? local.zone : local.region
  cluster  = google_container_cluster.primary.name

  # if we are 'regional' i.e. in 3 zones,
  # "1" here means "1 in each zone"
  initial_node_count = var.zonal_cluster ? "3" : "1"

  autoscaling {
    min_node_count = "0"
    max_node_count = var.zonal_cluster ? var.max_node_count : ceil(var.max_node_count / 3)
  }

  management {
    auto_upgrade = true

    # https://cloud.google.com/kubernetes-engine/docs/how-to/node-auto-repair
    auto_repair = true
  }

  node_config {

    labels = {
      "astronomer.io/dynamic-pods" = "true"
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
      for_each = var.dp_node_pool_taints
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

  # By not setting the name, this allows the provider to choose a random name.
  # This is good because we can create_before_destroy (if name is hardcoded,
  # then it is a name collision), and we can also avoid re-provisioning the
  # whole node pool when something needs to update, which would happen if we
  # include a timestamp or similar in the name. If we provided a random string
  # using one of the terraform 'random_' resources, then it would also cause
  # name collisions because terraform would not change the random value. If
  # we force the random value to always update, then that has the same behavior
  # as including a timestamp.
  #
  # name    = "${var.deployment_id}-platform-${formatdate("MM-DD-hh-mm", timestamp())}"

  # not working because 'inconsistent final plan'
  # timeouts {
  #   create = "30m"
  #   update = "30m"
  #   delete = "30m"
  # }

  # Use auto-upgrade for versioning of this node pool
  # version = data.google_container_cluster.primary.master_version
  # version = var.kube_version_gke

  location = var.zonal_cluster ? local.zone : local.region
  cluster  = google_container_cluster.primary.name

  # if we are 'regional' i.e. in 3 zones,
  # "1" here means "1 in each zone"
  initial_node_count = var.zonal_cluster ? "3" : "1"

  autoscaling {
    min_node_count = "0"
    max_node_count = var.zonal_cluster ? 12 : 4
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
  }
}
