data "google_project" "project" {}

resource "google_service_account_key" "default_key" {
  service_account_id = google_service_account.k8s_registry.account_id
  public_key_type    = "TYPE_X509_PEM_FILE"
}

resource "google_storage_bucket_iam_member" "registry_user" {
  bucket = google_storage_bucket.container_registry.name
  member = "serviceAccount:${google_service_account.k8s_registry.email}"
  role   = "roles/storage.legacyBucketOwner"
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
  project = data.google_project.project.project_id
}

resource "google_service_account_key" "velero" {
  service_account_id = google_service_account.velero.account_id
}

resource "google_project_iam_custom_role" "velero_server" {
  role_id = "velero.server.${var.deployment_id}"
  title   = "Velero Server"

  project = data.google_project.project.project_id

  permissions = [
    "compute.disks.get",
    "compute.disks.create",
    "compute.disks.createSnapshot",
    "compute.snapshots.get",
    "compute.snapshots.create",
    "compute.snapshots.useReadOnly",
    "compute.snapshots.delete",
    "compute.zones.get",
    "storage.objects.list"
  ]
}

resource "google_project_iam_member" "velero_server" {
  member  = "serviceAccount:${google_service_account.velero.email}"
  role    = google_project_iam_custom_role.velero_server.id
  project = data.google_project.project.project_id
}

resource "google_storage_bucket_iam_member" "velero_server" {
  bucket = google_storage_bucket.velero_k8s_backup.name
  member = "serviceAccount:${google_service_account.velero.email}"
  role   = "roles/storage.objectAdmin"
}
