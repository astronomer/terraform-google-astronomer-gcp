data "google_client_config" "current" {}

resource "google_storage_bucket" "container_registry" {
  name          = "${data.google_client_config.current.project}-registry"
  location      = "${var.region}"
  storage_class = "MULTI_REGIONAL"
  force_destroy = "true"

  labels = {
    "managed-by" = "terraform"
  }
}
