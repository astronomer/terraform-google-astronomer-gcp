# https://www.terraform.io/docs/providers/google/r/compute_router_nat.html
# VPC network
resource "google_compute_network" "core" {
  name                    = "${var.deployment_id}-core-network"
  auto_create_subnetworks = false

}

#Subnetwork
resource "google_compute_subnetwork" "gke" {
  name          = "${var.deployment_id}-gke-subnet"
  network       = google_compute_network.core.self_link
  ip_cidr_range = "10.0.0.0/16"
  region        = local.region

  private_ip_google_access = true

  secondary_ip_range {
    range_name    = "${var.deployment_id}-gke-pods"
    ip_cidr_range = var.gke_secondary_ip_ranges_pods
  }

  secondary_ip_range {
    range_name    = "${var.deployment_id}-gke-services"
    ip_cidr_range = var.gke_secondary_ip_ranges_services
  }

}

# Router
resource "google_compute_router" "router" {
  name    = "${var.deployment_id}-router"
  region  = google_compute_subnetwork.gke.region
  network = google_compute_network.core.self_link

  bgp {
    keepalive_interval = 0
    asn                = 64514
  }

}

# IP address
resource "google_compute_address" "address" {
  count  = 1
  name   = "${var.deployment_id}-nat-external-address-${count.index}"
  region = local.region
}

# Cloud NAT
resource "google_compute_router_nat" "nat" {

  name                                = "${var.deployment_id}-gke-${formatdate("MM-DD-hh-mm", timestamp())}"
  region                              = local.region
  max_ports_per_vm                    = var.router_nat_max_port_vm
  min_ports_per_vm                    = var.router_nat_min_port_vm
  enable_dynamic_port_allocation      = var.router_nat_enable_dynamic_port_allocation
  router                              = google_compute_router.router.name
  nat_ip_allocate_option              = "MANUAL_ONLY"
  nat_ips                             = length(var.natgateway_external_ip_list) == 0 ? google_compute_address.address.*.self_link : var.natgateway_external_ip_list
  source_subnetwork_ip_ranges_to_nat  = "LIST_OF_SUBNETWORKS"
  tcp_established_idle_timeout_sec    = 7200
  enable_endpoint_independent_mapping = var.router_nat_enable_endpoint_independent_mapping

  log_config {
    enable = false
    filter = "ALL"
  }

  lifecycle {
    ignore_changes = [name]
  }

  subnetwork {
    name                    = google_compute_subnetwork.gke.self_link
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  dynamic "subnetwork" {
    for_each = var.management_endpoint == "public" ? [] : ["placeholder"]
    content {
      name                    = google_compute_subnetwork.bastion[0].self_link
      source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
    }
  }
}

# https://cloud.google.com/vpc/docs/configure-private-services-access#creating-connection
# Required for connecting the bastion subnetwork to the
# EKS private API network and for connecting the EKS
# network to the SQL database network
resource "google_compute_global_address" "private_ip_address" {
  provider      = google-beta
  name          = "${var.deployment_id}-private-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.core.self_link
  project       = data.google_project.project.project_id
}

# Required for connecting the bastion subnetwork to the
# EKS private API network and for connecting the EKS
# network to the SQL database network
resource "google_service_networking_connection" "private_vpc_connection" {
  provider                = google-beta
  network                 = google_compute_network.core.self_link
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]

}

// - Bastion Subnetwork --------------------------------------------------
resource "google_compute_subnetwork" "bastion" {
  count         = var.management_endpoint == "public" ? 0 : 1
  name          = "${var.deployment_id}-bastion-subnet"
  network       = google_compute_network.core.self_link
  ip_cidr_range = "10.1.0.0/29"
  region        = local.region

  private_ip_google_access = true
}
