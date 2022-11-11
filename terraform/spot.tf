resource "spotinst_ocean_gke_import" "ocean" {
  count = var.enable_spotinist ? 1 : 0

  cluster_name = google_container_cluster.primary.name
  location     = local.location

  max_size = 1000

  whitelist = [
    "n1-standard-4",
    "n1-standard-8",
    "n1-standard-16",
    "n1-standard-32",
    "n1-standard-64",
    "n1-standard-96",
    "n1-highmem-4",
    "n1-highmem-8",
    "n1-highmem-16",
    "n1-highmem-32",
    "n1-highmem-96",
    "n1-highmem-64",
    "n1-highcpu-4",
    "n1-highcpu-8",
    "n1-highcpu-16",
    "n1-highcpu-32",
    "n1-highcpu-64",
    "n1-highcpu-96",
    "n1-ultramem-40",
    "n1-ultramem-80"
  ]
}

resource "spotinst_ocean_gke_launch_spec_import" "platform_blue" {
  count          = var.enable_spotinist && var.enable_blue_platform_node_pool ? 1 : 0
  ocean_id       = spotinst_ocean_gke_import.ocean.0.id
  node_pool_name = google_container_node_pool.node_pool_platform[count.index].name
  lifecycle {
    create_before_destroy = true
  }
}

resource "spotinst_ocean_gke_launch_spec_import" "platform_green" {
  count          = var.enable_spotinist && var.enable_green_platform_node_pool ? 1 : 0
  ocean_id       = spotinst_ocean_gke_import.ocean.0.id
  node_pool_name = google_container_node_pool.node_pool_platform_green[count.index].name
  lifecycle {
    create_before_destroy = true
  }
}

resource "spotinst_ocean_gke_launch_spec_import" "mt_blue" {
  count          = var.enable_spotinist && var.enable_blue_mt_node_pool ? 1 : 0
  ocean_id       = spotinst_ocean_gke_import.ocean.0.id
  node_pool_name = google_container_node_pool.node_pool_mt[count.index].name
  lifecycle {
    create_before_destroy = true
  }
}

resource "spotinst_ocean_gke_launch_spec_import" "mt_green" {
  count          = var.enable_spotinist && var.enable_green_mt_node_pool ? 1 : 0
  ocean_id       = spotinst_ocean_gke_import.ocean.0.id
  node_pool_name = google_container_node_pool.node_pool_mt_green[count.index].name
  lifecycle {
    create_before_destroy = true
  }
}

resource "spotinst_ocean_gke_launch_spec_import" "dynamic_pods" {
  count          = var.enable_spotinist && var.create_dynamic_pods_nodepool ? 1 : 0
  ocean_id       = spotinst_ocean_gke_import.ocean.0.id
  node_pool_name = google_container_node_pool.node_pool_dynamic_pods[count.index].name
  lifecycle {
    create_before_destroy = true
  }
}
