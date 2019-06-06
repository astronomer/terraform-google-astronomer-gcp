/*
Wildcard SSL certificate
created with Let's Encrypt
and Google Cloud DNS
*/

# We expect to start out with a DNS managed zone as an input
# rather than creating one ourselves. I had an issue making
# it fully automatic. In addition, this way we can share the
# zone between developers.
# https://issuetracker.google.com/issues/133640275

/*
resource "random_id" "collision_avoidance" {
  byte_length = 4
}
resource "google_dns_managed_zone" "public_zone" {
  name     = "${var.deployment_id}-zone-${random_id.collision_avoidance.hex}"
  dns_name = "${var.google_domain}."
}
*/

data "google_dns_managed_zone" "public_zone" {
  name = "${var.dns_managed_zone}"
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
  common_name     = "*.${local.base_domain}"

  dns_challenge {
    provider = "gcloud"

    config {
      GCE_PROJECT             = "${var.project}"
      GCE_PROPAGATION_TIMEOUT = "300"
      GCE_SERVICE_ACCOUNT_FILE = "${pathexpand(var.gce_service_account_file)}"
    }
  }
}

resource "google_compute_address" "nginx_static_ip" {
  name = "${var.deployment_id}-nginx-static-ip"
}

resource "google_dns_record_set" "a_record" {
  name         = "*.${local.base_domain}."
  managed_zone = "${data.google_dns_managed_zone.public_zone.name}"
  type         = "A"
  ttl          = 300
  rrdatas      = ["${google_compute_address.nginx_static_ip.address}"]
}
