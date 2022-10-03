# The data source is necessary to get the current
# master kube version instead of the previous version
data "google_container_cluster" "primary" {
  name     = google_container_cluster.primary.name
  location = google_container_cluster.primary.location
}

## Multi-tenant node-pool green

resource "google_container_node_pool" "node_pool_mt_green" {

  count = var.enable_green_mt_node_pool ? 1 : 0

  provider = google-beta

  version = var.kube_version_gke

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
  initial_node_count = var.green_mt_np_initial_node_count

  autoscaling {
    min_node_count = "0"
    max_node_count = var.enable_spotinist ? "1" : var.zonal_cluster ? var.max_node_count_multi_tenant_green : ceil(var.max_node_count_multi_tenant_green / 3)
  }

  management {
    # https://cloud.google.com/kubernetes-engine/docs/how-to/node-auto-upgrades
    # With this set to false, then an update will only occur when terraform runs
    # because we set the node pool kubelet version to the version of the master,
    # which will trigger an update, and the name including a timestamp will
    # force a create then destroy event.
    auto_upgrade = true

    # https://cloud.google.com/kubernetes-engine/docs/how-to/node-auto-repair
    auto_repair = true
  }

  node_config {

    labels = {
      "astronomer.io/multi-tenant" = "true"
      # add in later if you are re-creating this node pool
      # "astronomer.io/node-pool"    = "mt_green"
    }

    machine_type = var.machine_type_multi_tenant_green
    disk_size_gb = var.disk_size_multi_tenant_green

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
      for_each = var.mt_node_pool_taints_green
      content {
        effect = taint.value.effect
        key    = taint.value.key
        value  = taint.value.value
      }
    }

    # COS_CONTAINERD is required for sandbox_config to work
    image_type = var.enable_gvisor_green ? "COS_CONTAINERD" : "COS"

    # Only include sandbox config if we are using gvisor
    dynamic "sandbox_config" {
      for_each = var.enable_gvisor_green ? ["placeholder"] : []
      content {
        sandbox_type = "gvisor"
      }
    }

  }

  lifecycle {
    ignore_changes = [
      initial_node_count
    ]
  }
}

## Multi-tenant node pool blue

resource "google_container_node_pool" "node_pool_mt" {

  count    = var.enable_blue_mt_node_pool ? 1 : 0
  project  = data.google_project.project.project_id
  provider = google-beta

  version = var.kube_version_gke

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
  initial_node_count = var.blue_mt_np_initial_node_count

  autoscaling {
    min_node_count = "0"
    max_node_count = var.enable_spotinist ? "1" : var.zonal_cluster ? var.max_node_count_multi_tenant_blue : ceil(var.max_node_count_multi_tenant_blue / 3)
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
      "astronomer.io/node-pool"    = "mt_blue"
    }

    machine_type = var.machine_type_multi_tenant_blue
    disk_size_gb = var.disk_size_multi_tenant_blue

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
      for_each = var.mt_node_pool_taints_blue
      content {
        effect = taint.value.effect
        key    = taint.value.key
        value  = taint.value.value
      }
    }

    # COS_CONTAINERD is required for sandbox_config to work
    image_type = var.enable_gvisor_blue ? "COS_CONTAINERD" : "COS"

    # Only include sandbox config if we are using gvisor
    dynamic "sandbox_config" {
      for_each = var.enable_gvisor_blue ? ["placeholder"] : []
      content {
        sandbox_type = "gvisor"
      }
    }

  }

  lifecycle {
    ignore_changes = [
      initial_node_count
    ]
  }
}

## Legacy dynamic pods pool (before dynamic pods blue/green)

resource "google_container_node_pool" "node_pool_dynamic_pods" {
  count = var.create_dynamic_pods_nodepool ? 1 : 0

  provider = google-beta

  version = var.kube_version_gke

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
  initial_node_count = var.dynamic_np_initial_node_count

  autoscaling {
    min_node_count = "0"
    max_node_count = var.enable_spotinist ? "1" : var.zonal_cluster ? var.max_node_count_dynamic : ceil(var.max_node_count_dynamic / 3)
  }

  management {
    auto_upgrade = true

    # https://cloud.google.com/kubernetes-engine/docs/how-to/node-auto-repair
    auto_repair = true
  }

  node_config {

    labels = {
      "astronomer.io/multi-tenant" = "true"
      "astronomer.io/dynamic-pods" = "true"
      "astronomer.io/node-pool"    = "dynamic_pods_legacy"
    }

    machine_type = var.machine_type_dynamic
    disk_size_gb = var.disk_size_dynamic

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
      for_each = var.dynamic_node_pool_taints
      content {
        effect = taint.value.effect
        key    = taint.value.key
        value  = taint.value.value
      }
    }

    # COS_CONTAINERD is required for sandbox_config to work
    image_type = var.enable_gvisor_dynamic ? "COS_CONTAINERD" : "COS"

    # Only include sandbox config if we are using gvisor
    dynamic "sandbox_config" {
      for_each = var.enable_gvisor_dynamic ? ["placeholder"] : []
      content {
        sandbox_type = "gvisor"
      }
    }

  }

  lifecycle {
    ignore_changes = [
      initial_node_count
    ]
  }
}

## Blue dynamic pods pool (added 2020-12-16)

resource "google_container_node_pool" "dynamic_blue_node_pool" {
  count = var.enable_dynamic_blue_node_pool ? 1 : 0

  provider = google-beta

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
  initial_node_count = var.dynamic_blue_np_initial_node_count

  autoscaling {
    min_node_count = "0"
    max_node_count = var.enable_spotinist ? "1" : var.zonal_cluster ? var.dynamic_blue_np_initial_node_count : ceil(var.max_node_count_dynamic_blue / 3)
  }

  management {
    auto_upgrade = true

    # https://cloud.google.com/kubernetes-engine/docs/how-to/node-auto-repair
    auto_repair = true
  }

  node_config {

    labels = {
      "astronomer.io/multi-tenant" = "true"
      "astronomer.io/dynamic-pods" = "true"
      "astronomer.io/node-pool"    = "dynamic_blue"
    }

    machine_type = var.machine_type_dynamic_blue
    disk_size_gb = var.disk_size_dynamic_blue
    disk_type    = var.disk_type_dynamic_blue

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
      for_each = var.dynamic_blue_node_pool_taints
      content {
        effect = taint.value.effect
        key    = taint.value.key
        value  = taint.value.value
      }
    }

    # COS_CONTAINERD is required for sandbox_config to work
    image_type = var.enable_gvisor_dynamic_blue ? "COS_CONTAINERD" : "COS"

    # Only include sandbox config if we are using gvisor
    dynamic "sandbox_config" {
      for_each = var.enable_gvisor_dynamic_blue ? ["placeholder"] : []
      content {
        sandbox_type = "gvisor"
      }
    }

  }

  lifecycle {
    ignore_changes = [
      initial_node_count
    ]
  }
}

## Green dynamic pods pool (added 2020-12-16)

resource "google_container_node_pool" "dynamic_green_node_pool" {
  count = var.enable_dynamic_green_node_pool ? 1 : 0

  provider = google-beta

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
  initial_node_count = var.dynamic_green_np_initial_node_count

  autoscaling {
    min_node_count = "0"
    max_node_count = var.enable_spotinist ? "1" : var.zonal_cluster ? var.dynamic_green_np_initial_node_count : ceil(var.max_node_count_dynamic_green / 3)
  }

  management {
    auto_upgrade = true

    # https://cloud.google.com/kubernetes-engine/docs/how-to/node-auto-repair
    auto_repair = true
  }

  node_config {

    labels = {
      "astronomer.io/multi-tenant" = "true"
      "astronomer.io/dynamic-pods" = "true"
      "astronomer.io/node-pool"    = "dynamic_green"
    }

    machine_type = var.machine_type_dynamic_green
    disk_size_gb = var.disk_size_dynamic_green
    disk_type    = var.disk_type_dynamic_green

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
      for_each = var.dynamic_green_node_pool_taints
      content {
        effect = taint.value.effect
        key    = taint.value.key
        value  = taint.value.value
      }
    }

    # COS_CONTAINERD is required for sandbox_config to work
    image_type = var.enable_gvisor_dynamic_green ? "COS_CONTAINERD" : "COS"

    # Only include sandbox config if we are using gvisor
    dynamic "sandbox_config" {
      for_each = var.enable_gvisor_dynamic_green ? ["placeholder"] : []
      content {
        sandbox_type = "gvisor"
      }
    }

  }

  lifecycle {
    ignore_changes = [
      initial_node_count
    ]
  }
}

## Platform node-pool blue

resource "google_container_node_pool" "node_pool_platform" {

  count    = var.enable_blue_platform_node_pool ? 1 : 0
  project  = data.google_project.project.project_id
  provider = google-beta
  version  = var.kube_version_gke

  location = var.zonal_cluster ? local.zone : local.region
  cluster  = google_container_cluster.primary.name

  # if we are 'regional' i.e. in 3 zones,
  # "1" here means "1 in each zone"
  initial_node_count = var.blue_platform_np_initial_node_count

  autoscaling {
    min_node_count = "1"
    max_node_count = var.enable_spotinist ? "1" : var.zonal_cluster ? var.max_node_count_platform_blue : ceil(var.max_node_count_platform_blue / 3)
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

    machine_type = var.machine_type_platform_blue
    disk_size_gb = var.disk_size_platform_blue

    labels = {
      "astronomer.io/multi-tenant" = "false"
      "astronomer.io/node-pool"    = "platform_blue"
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
      for_each = var.platform_node_pool_taints_blue
      content {
        effect = taint.value.effect
        key    = taint.value.key
        value  = taint.value.value
      }
    }
  }

  # this one can take a long time to delete or create
  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      initial_node_count
    ]
  }
}

## Platform node-pool green

resource "google_container_node_pool" "node_pool_platform_green" {
  count = var.enable_green_platform_node_pool ? 1 : 0

  provider = google-beta
  version  = var.kube_version_gke
  location = var.zonal_cluster ? local.zone : local.region
  cluster  = google_container_cluster.primary.name

  # if we are 'regional' i.e. in 3 zones,
  # "1" here means "1 in each zone"
  initial_node_count = var.green_platform_np_initial_node_count

  autoscaling {
    min_node_count = "1"
    max_node_count = var.enable_spotinist ? "1" : var.zonal_cluster ? var.max_node_count_platform_green : ceil(var.max_node_count_platform_green / 3)
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

    machine_type = var.machine_type_platform_green
    disk_size_gb = var.disk_size_platform_green

    labels = {
      "astronomer.io/multi-tenant" = "false"
      # add in later if you are re-creating this node pool
      # "astronomer.io/node-pool"    = "platform_green"
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
      for_each = var.platform_node_pool_taints_green
      content {
        effect = taint.value.effect
        key    = taint.value.key
        value  = taint.value.value
      }
    }
  }

  # this one can take a long time to delete or create
  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      initial_node_count
    ]
  }
}
