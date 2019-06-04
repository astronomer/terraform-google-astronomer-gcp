# Service account
resource "google_service_account" "bastion" {
  account_id   = "${var.deployment_id}-bastion"
  display_name = "${var.deployment_id}-bastion"
}
