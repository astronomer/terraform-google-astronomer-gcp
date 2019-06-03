/*
Wildcard SSL certificate
created with Let's Encrypt
and AWS Route 53
*/

provider "acme" {
  server_url = "${var.acme_server}"
}

resource "tls_private_key" "private_key" {
  algorithm = "RSA"
}

resource "acme_registration" "user_registration" {
  account_key_pem = "${tls_private_key.private_key.private_key_pem}"
  email_address   = "${var.admin_email}"
}

resource "acme_certificate" "lets_encrypt" {
  account_key_pem = "${acme_registration.user_registration.account_key_pem}"
  common_name     = "*.${var.customer_id}.${var.route53_domain}"

  dns_challenge {
    provider = "route53"
  }
}

data "aws_route53_zone" "selected" {
  name = "${var.route53_domain}."
}

resource "aws_route53_record" "astronomer" {
  zone_id = "${data.aws_route53_zone.selected.zone_id}"
  name    = "*.${var.customer_id}.${data.aws_route53_zone.selected.name}"
  type    = "CNAME"
  ttl     = "5"
  records = ["${data.aws_elb.nginx_elb.dns_name}"]
}
