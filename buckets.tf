data "google_client_config" "current" {
}

resource "google_storage_bucket" "container_registry" {
  name          = "${var.deployment_id}-${data.google_client_config.current.project}-registry"
  location      = local.region
  storage_class = "REGIONAL"
  force_destroy = "true"

  labels = {
    "managed-by" = "terraform"
  }

}

resource "google_storage_bucket" "velero_k8s_backup" {
  name          = "${var.deployment_id}-velero-backups"
  location      = local.region
  storage_class = "REGIONAL"
  force_destroy = "true"

  labels = {
    "managed-by" = "terraform"
  }
}
