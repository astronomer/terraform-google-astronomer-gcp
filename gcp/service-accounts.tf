# Service account
resource "google_service_account" "bastion" {
  account_id   = "${var.label}-bastion"
  display_name = "${var.label}-bastion"
}
