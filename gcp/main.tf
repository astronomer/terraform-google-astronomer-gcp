variable region {
  default     = "us-east4"
  description = "The GCP region to deploy infrastructure into"
}

variable zone {
  default     = "us-east4-a"
  description = "The GCP zone to deploy infrastructure into"
}

variable project {
  description = "The GCP project to deploy infrastructure into"
}

variable cluster_name {
  description = "The name of the GKE cluster"
}

variable machine_type {
  default     = "n1-standard-8"
  description = "The GCP machine type for GKE worker nodes"
}

variable min_node_count {
  default     = 3
  description = "The minimum amount of worker nodes in GKE cluster"
}

variable max_node_count {
  default     = 10
  description = "The maximum amount of worker nodes in GKE cluster"
}

variable node_version {
  default     = "1.11.7-gke.12"
  description = "The version of Kubernetes in GKE cluster"
}

provider google {
  region  = "${var.region}"
  project = "${var.project}"
}

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
  name    = "${var.cluster_name}-np-${random_string.network_tag.result}"
  location    = "${var.region}"
  cluster = "${google_container_cluster.primary.name}"

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
  location               = "${var.region}"
  min_master_version = "${var.node_version}"
  node_version       = "${var.node_version}"
  enable_legacy_abac = false
  network = "${google_compute_network.default.self_link}"
  subnetwork = "${google_compute_subnetwork.default.self_link}"

  ip_allocation_policy {
    use_ip_aliases = true
  }

  private_cluster_config {
    enable_private_nodes = true
    master_ipv4_cidr_block = "172.16.0.0/28"
  }
  
  master_authorized_networks_config {
    cidr_blocks = [{ cidr_block = "${google_compute_instance.bastion.network_interface.0.access_config.0.nat_ip}/32" }]
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

# Bastion host
resource "google_compute_instance" "bastion" {
  name         = "bastion"
  machine_type = "${var.machine_type}"
  zone         = "${var.zone}"

  boot_disk {
    initialize_params {
      image = "ubuntu-1804-bionic-v20190404"
    }
  }

  network_interface {
    subnetwork = "default"

    access_config {
      # Ephemeral IP - leaving this block empty will generate a new external IP and assign it to the machine
    }
  }
  
  service_account {
    email = "${google_service_account.admin.email}"
    scopes = ["cloud-platform"]
  }

  tags = ["bastion"]
}

# Service account
resource "google_service_account" "admin" {
  account_id   = ""
  display_name = ""
}

# Role binding to service account
resource "google_project_iam_binding" "astro" {
  project = "${var.project}"
  role    = "roles/container.admin"

  members = [
    "serviceAccount:${google_service_account.admin.email}",
  ]
}

# IP address
resource "google_compute_address" "address" {
  count  = 1
  name   = "nat-external-address-${count.index}"
  region = "${var.region}"
}

# Router
resource "google_compute_router" "router" {
  name    = "router"
  region  = "${google_compute_subnetwork.default.region}"
  network = "${google_compute_network.default.self_link}"
  bgp {
    asn = 64514
  }
}

# VPC network
resource "google_compute_network" "default" {
  name = "my-network"
}

#Subnetwork
resource "google_compute_subnetwork" "default" {
  name          = "my-subnet"
  network       = "${google_compute_network.default.self_link}"
  ip_cidr_range = "10.0.0.0/16"
  region        = "${var.region}"
}

# Cloud NAT
resource "google_compute_router_nat" "nat" {
  name = "nat-1"
  region = "${var.region}"
  router = "${google_compute_router.router.name}"
  nat_ip_allocate_option = "MANUAL_ONLY"
  nat_ips = ["${google_compute_address.address.*.self_link}"]
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  subnetwork {
    name = "${google_compute_subnetwork.default.self_link}"
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
}

output "bastion_ip" {
  value = "${google_compute_instance.bastion.network_interface.0.access_config.0.nat_ip}"
}