data "google_client_config" "current" {}

resource "google_storage_bucket" "container_registry" {
  name          = "${var.deployment_id}-${data.google_client_config.current.project}-registry"
  location      = "${var.region}"
  storage_class = "REGIONAL"
  force_destroy = "true"

  labels = {
    "managed-by" = "terraform"
  }
}
