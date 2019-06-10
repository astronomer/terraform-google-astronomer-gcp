# permissions to 
resource "google_project_iam_binding" "container_admin" {
  role = "roles/container.admin"
  members = formatlist("user:%s", var.admin_emails)
}

resource "google_project_iam_binding" "compute_os_login_users" {
  role = "roles/compute.osLogin"
  members = formatlist("user:%s", var.admin_emails)
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

