# Role binding to service account
resource "google_project_iam_binding" "admin" {
  project = "${var.project}"
  role    = "roles/container.admin"

  members = [
    "serviceAccount:${google_service_account.admin.email}",
  ]
}

resource "google_project_iam_binding" "read-only" {
  project = "${var.project}"
  role    = "roles/container.viewer"

  members = [
    "serviceAccount:${google_service_account.read-only.email}",
  ]
}

resource "google_project_iam_member" "compute-os-login" {
  project = "${var.project}"
  role    = "roles/compute.osLogin"
  member  = "serviceAccount:${google_service_account.read-only.email}"
}
