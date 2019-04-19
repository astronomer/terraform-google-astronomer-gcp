# VPC network
resource "google_compute_network" "default" {
  name                    = "my-network"
  auto_create_subnetworks = false
  project                 = "${var.project}"
}

#Subnetwork
resource "google_compute_subnetwork" "default" {
  name          = "my-subnet"
  network       = "${google_compute_network.default.self_link}"
  ip_cidr_range = "10.0.0.0/16"
  region        = "${var.region}"
  project       = "${var.project}"

  private_ip_google_access = true

  secondary_ip_range {
    range_name    = "gke-${var.cluster_name}-pods"
    ip_cidr_range = "${var.gke_secondary_ip_ranges_pods}"
  }

  secondary_ip_range {
    range_name    = "gke-${var.cluster_name}-services"
    ip_cidr_range = "${var.gke_secondary_ip_ranges_services}"
  }
}

# Cloud NAT
resource "google_compute_router_nat" "nat" {
  name                               = "nat-1"
  region                             = "${var.region}"
  router                             = "${google_compute_router.router.name}"
  nat_ip_allocate_option             = "MANUAL_ONLY"
  nat_ips                            = ["${google_compute_address.address.*.self_link}"]
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  project                            = "${var.project}"

  subnetwork {
    name                    = "${google_compute_subnetwork.default.self_link}"
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
}

resource "google_compute_global_address" "private_ip_address" {
  provider = "google-beta"

  name          = "private-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = "${google_compute_network.default.self_link}"
}

resource "google_service_networking_connection" "private_vpc_connection" {
  provider = "google-beta"

  network                 = "${google_compute_network.default.self_link}"
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = ["${google_compute_global_address.private_ip_address.name}"]
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
  project = "${var.project}"

  bgp {
    asn = 64514
  }
}
