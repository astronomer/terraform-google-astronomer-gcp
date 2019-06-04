/*
Wildcard SSL certificate
created with Let's Encrypt
and Google Cloud DNS
*/

resource "random_id" "collision_avoidance" {
  byte_length = 4
}

resource "google_dns_managed_zone" "public_zone" {
  name     = "${var.deployment_id}-zone-${random_id.collision_avoidance.hex}"
  dns_name = "${var.google_domain}."
}

provider "acme" {
  server_url = "${var.acme_server}"
}

resource "tls_private_key" "private_key" {
  algorithm = "RSA"
}

resource "acme_registration" "user_registration" {
  account_key_pem = "${tls_private_key.private_key.private_key_pem}"
  email_address   = "${var.bastion_admin_emails[0]}"
}

resource "acme_certificate" "lets_encrypt" {
  account_key_pem = "${acme_registration.user_registration.account_key_pem}"
  common_name     = "*.astro.${var.google_domain}"

  # Let's encrypt uses Google's nameservers,
  # so it makes sense for us to check there.
  recursive_nameservers = ["8.8.8.8:53", "8.8.4.4:53"]

  dns_challenge {
    provider = "gcloud"

    config {
      GCE_PROJECT             = "${var.project}"
      GCE_PROPAGATION_TIMEOUT = "300"
    }
  }
}

resource "google_compute_address" "nginx_address" {
  name = "${var.deployment_id}-nginx-address"
}

resource "google_dns_record_set" "a_record" {
  name         = "*.astro.${google_dns_managed_zone.public_zone.dns_name}"
  managed_zone = "${google_dns_managed_zone.public_zone.name}"
  type         = "A"
  ttl          = 300
  rrdatas      = ["${google_compute_address.nginx_address.address}"]
}
