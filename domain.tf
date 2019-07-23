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

data "google_dns_managed_zone" "public_zone" {
  name = var.dns_managed_zone
}

resource "tls_private_key" "private_key" {
  algorithm = "RSA"
}

resource "acme_registration" "user_registration" {
  account_key_pem = tls_private_key.private_key.private_key_pem
  email_address   = var.email
}

resource "tls_private_key" "cert_private_key" {
  algorithm = "RSA"
}

resource "tls_cert_request" "req" {
  key_algorithm   = "RSA"
  private_key_pem = tls_private_key.cert_private_key.private_key_pem
  dns_names       = ["*.${local.base_domain}"]

  subject {
    common_name  = "*.${local.base_domain}"
    organization = "Astronomer"
  }
}

resource "acme_certificate" "lets_encrypt" {
  account_key_pem         = acme_registration.user_registration.account_key_pem
  certificate_request_pem = tls_cert_request.req.cert_request_pem
  recursive_nameservers   = data.google_dns_managed_zone.public_zone.name_servers

  dns_challenge {
    provider = "gcloud"

    config = {
      GCE_PROJECT             = local.project
      GCE_PROPAGATION_TIMEOUT = "300"
    }
  }
}

resource "google_compute_address" "nginx_static_ip" {
  name = "${var.deployment_id}-nginx-static-ip"
}

resource "google_dns_record_set" "a_record" {
  count        = var.do_not_create_a_record ? 0 : 1
  name         = "*.${local.base_domain}."
  managed_zone = data.google_dns_managed_zone.public_zone.name
  type         = "A"
  ttl          = 300
  rrdatas      = [google_compute_address.nginx_static_ip.address]
}

