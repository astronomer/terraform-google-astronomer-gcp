resource "google_compute_firewall" "bastion_iap_ingress" {
  count       = var.management_endpoint == "public" ? 0 : 1
  name        = "${var.deployment_id}-bastion-iap-ingress"
  network     = google_compute_network.core.self_link
  description = "Allows SSH traffic (port 22) from the GCP's IAP CIDR range to Bastion"
  priority    = 10000
  direction   = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges           = var.iap_cidr_ranges
  target_service_accounts = [google_service_account.bastion[0].email]
}

resource "google_compute_firewall" "bastion_deny_all_ingress" {
  count       = var.management_endpoint == "public" ? 0 : 1
  name        = "${var.deployment_id}-bastion-deny-all-ingress"
  network     = google_compute_network.core.self_link
  description = "Denies all ingress traffic on bastion"
  priority    = 65534
  direction   = "INGRESS"

  deny {
    protocol = "all"
  }

  target_service_accounts = [google_service_account.bastion[0].email]
}

resource "google_compute_firewall" "gke_webhook_allow" {
  name        = "${var.deployment_id}-apiservice-webhook-allow-ingress-from-gke-masters"
  network     = google_compute_network.core.self_link
  description = "Allow GKE control plane to communicate with node pools on the ports required to enable custom api services"
  priority    = 1000
  direction   = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = var.webhook_ports
  }

  source_ranges = [google_container_cluster.primary.private_cluster_config.0.master_ipv4_cidr_block]
  target_tags   = local.gke_nodepool_network_tags
}

resource "google_compute_firewall" "gke_iap_ssh_to_nodes" {
  name        = "${var.deployment_id}-allow-ingress-from-google-iap-to-nodes"
  network     = google_compute_network.core.self_link
  description = "Allow GCP IAP to use SSH to connect to GKE nodes"
  priority    = 2000
  direction   = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = var.iap_cidr_ranges
  target_tags   = local.gke_nodepool_network_tags
}

# Istio Firewall rule
# ref: https://istio.io/latest/docs/setup/platform-setup/gke/
resource "google_compute_firewall" "istio_firewall_rule" {

  count = var.enable_istio ? 1 : 0

  name        = google_container_cluster.primary.name
  network     = google_compute_network.core.name
  description = "Allow Istio to perform Pilot discovery validation webhook."

  allow {
    protocol = "tcp"
    ports    = ["10250", "443", "15017"]
  }

  source_ranges = [google_container_cluster.primary.private_cluster_config.0.master_ipv4_cidr_block]
}
