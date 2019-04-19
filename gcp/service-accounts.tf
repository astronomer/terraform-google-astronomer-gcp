# Service account
resource "google_service_account" "admin" {
  account_id   = "cluster-admin"
  display_name = "Cluster Admin"
}

resource "google_service_account" "read-only" {
  account_id   = "cluster-read-only"
  display_name = "Cluster Read Only"
}

# Service account key
resource "google_service_account_key" "mykey" {
  service_account_id = "${google_service_account.admin.name}"
  private_key_type   = "TYPE_GOOGLE_CREDENTIALS_FILE"
}
