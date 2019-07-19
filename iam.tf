data "google_compute_default_service_account" "default" {}

resource "google_service_account_key" "default_key" {
  service_account_id = "${data.google_compute_default_service_account.default.name}"
  public_key_type    = "TYPE_X509_PEM_FILE"
}

resource "google_project_iam_member" "container_viewer" {
  count  = var.management_endpoint == "public" ? 0 : 1
  role   = "roles/container.viewer"
  member = "serviceAccount:${google_service_account.bastion[0].email}"
}

// Enables Audit Logs of Users SSH session into Bastion via IAP in StackDriver
resource "google_project_iam_audit_config" "iap" {
  audit_log_config {
    log_type = "DATA_READ"
  }

  audit_log_config {
    log_type = "DATA_WRITE"
  }

  audit_log_config {
    log_type = "ADMIN_READ"
  }

  service = "iap.googleapis.com"
}
