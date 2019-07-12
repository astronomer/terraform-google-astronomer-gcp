data "google_compute_default_service_account" "default" {}

resource "google_service_account_key" "default_key" {
  service_account_id = "${data.google_compute_default_service_account.default.name}"
  public_key_type    = "TYPE_X509_PEM_FILE"
}
