resource "random_string" "password" {
  length  = 16
  special = true
}

# Node pool
resource "google_container_node_pool" "np" {
  name = "${var.label}-node-pool"

  location = "${var.region}"
  cluster  = "${google_container_cluster.primary.name}"

  # since we are 'regional' i.e. in 3 zones,
  # "1" here means "1 in each zone"
  initial_node_count = "1"

  autoscaling {
    min_node_count = "0"
    max_node_count = "${ceil(var.max_node_count / 3.0)}"
  }

  management {
    # https://cloud.google.com/kubernetes-engine/docs/how-to/node-auto-upgrades
    # Relevant details:
    # - The process is to upgrade one node at a time
    # - "Pods on the node are rescheduled onto other nodes. If a Pod can't be rescheduled, that Pod stays in PENDING state until the node is recreated." This is an important detail, because this means that automatically-occuring updates could trigger pods to be in accessible.
    # - "If the new node fails to register as healthy, auto-upgrade of the entire node pool is disabled." TODO: ensure there is an alaram for this condition
    # - This is performed during a four-hour maintenence window. I don't know when that is, however.
    auto_upgrade = true

    # https://cloud.google.com/kubernetes-engine/docs/how-to/node-auto-repair
    # Relevant details:
    # - NotReady for > 10 minutes
    # - not reporting > 10 minutes
    # - boot disk out of space > 30 minutes
    # (you can check a node's healthchecks with 'kubectl get nodes')
    # 'repair' = drain and recreate node
    auto_repair = true
  }

  node_config {
    machine_type = "${var.machine_type}"

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
  provider = "google-beta"
  name     = "${var.label}-cluster"

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
  addons_config {
    istio_config {
      disabled = "${var.istio_disabled}"
      auth     = "${var.istio_auth}"
    }
  }
}
