# Service account
resource "google_service_account" "bastion" {
  account_id   = "bastion"
  display_name = "bastion"
}
