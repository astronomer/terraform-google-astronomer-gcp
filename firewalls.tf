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

resource "google_compute_firewall" "gke_knative_serving_webhook_allow" {
  count       = var.enable_knative ? 1 : 0
  name        = "${var.deployment_id}-knative-webhook-allow-ingress"
  network     = google_compute_network.core.self_link
  description = "Allow GKE master to communicate with node pools on 8443 for the knative webhook"
  priority    = 1000
  direction   = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["8443"]
  }

  source_ranges = [google_container_cluster.primary.private_cluster_config.0.master_ipv4_cidr_block]
  target_tags   = local.gke_nodepool_network_tags
}
