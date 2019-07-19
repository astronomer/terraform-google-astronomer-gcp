# Service account
resource "google_service_account" "bastion" {
  count        = var.management_endpoint == "public" ? 0 : 1
  account_id   = "${var.deployment_id}-bastion"
  display_name = "${var.deployment_id}-bastion"
}

