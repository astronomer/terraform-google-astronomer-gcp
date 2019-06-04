locals {
  bastion_name              = "${var.deployment_id}-bastion"
  postgres_airflow_password = "${ var.postgres_airflow_password == "" ? random_string.postgres_airflow_password.result : var.postgres_airflow_password }"
  core_network_id           = "${format("projects/%s/global/networks/%s", google_compute_network.core.project, google_compute_network.core.name)}"
  gke_subnetwork_id         = "${format("projects/%s/regions/%s/subnetworks/%s", google_compute_subnetwork.gke.project, google_compute_subnetwork.gke.region, google_compute_subnetwork.gke.name)}"
  # This is the only way I see to remove a trailing period,
  # this is quite ugly looking.
  base_domain = "${format("%s.%s", var.deployment_id, replace(chomp(replace(data.google_dns_managed_zone.public_zone.dns_name, ".", " ")), " ", "."))}"
}
