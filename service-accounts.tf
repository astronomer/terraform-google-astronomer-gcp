resource "google_service_account" "bastion" {
  count        = var.management_endpoint == "public" ? 0 : 1
  account_id   = "${var.deployment_id}-bastion"
  display_name = "${var.deployment_id}-bastion"
}

resource "google_service_account" "k8s_registry" {
  account_id   = "${var.deployment_id}-svc-registry"
  display_name = "${var.deployment_id}-svc-registry"
}
