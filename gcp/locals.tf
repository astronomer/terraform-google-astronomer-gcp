locals {
  bastion_name              = "${var.deployment_id}-bastion"
  postgres_airflow_password = "${ var.postgres_airflow_password == "" ? random_string.postgres_airflow_password.result : var.postgres_airflow_password }"
  core_network_id           = "${format("projects/%s/global/networks/%s", google_compute_network.core.project, google_compute_network.core.name)}"
  gke_subnetwork_id         = "${format("projects/%s/regions/%s/subnetworks/%s", google_compute_subnetwork.gke.project, google_compute_subnetwork.gke.region, google_compute_subnetwork.gke.name)}"
}
