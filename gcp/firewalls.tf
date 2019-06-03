resource "google_compute_firewall" "bastion_iap_ingress" {
  name        = "${var.deployment_id}-bastion-iap-ingress"
  network     = "${google_compute_network.core.self_link}"
  description = "Allows SSH traffic (port 22) from the GCP's IAP CIDR range to Bastion"
  priority    = 10000
  direction   = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["${var.iap_cidr_ranges}"]

  target_service_accounts = ["${google_service_account.bastion.email}"]
}

resource "google_compute_firewall" "bastion_deny_all_ingress" {
  name        = "${var.deployment_id}-bastion-deny-all-ingress"
  network     = "${google_compute_network.core.self_link}"
  description = "Denies all ingress traffic on bastion"
  priority    = 65534
  direction   = "INGRESS"

  deny {
    protocol = "all"
  }

  target_service_accounts = ["${google_service_account.bastion.email}"]
}
