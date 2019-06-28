# permissions to 
resource "google_project_iam_member" "container_admin" {
  count  = length(var.admin_emails)
  role   = "roles/container.admin"
  member = format("user:%s", var.admin_emails[count.index])
}

resource "google_project_iam_member" "compute_os_login_users" {
  count  = length(var.admin_emails)
  role   = "roles/compute.osLogin"
  member = format("user:%s", var.admin_emails[count.index])
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

