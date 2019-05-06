output "bastion_ip" {
  value       = "${google_compute_instance.bastion.network_interface.0.network_ip}"
  description = "Bastion IP Address"
}

output "postgres_ip" {
  value       = "${google_sql_database_instance.instance.ip_address.0.ip_address}"
  description = "Postgres IP Address"
}

output "postgres_user" {
  value       = "${google_sql_user.airflow.name}"
  description = "Postgres Username"
}

output "postgres_password" {
  value       = "${google_sql_user.airflow.password}"
  description = "Postgres Password"
}

output "bastion_subnetwork_selflink" {
  value       = "${google_compute_subnetwork.bastion.self_link}"
  description = "Selflink for the Bastion SubNetwork"
}

output "gke_subnetwork_selflink" {
  value       = "${google_compute_subnetwork.gke.self_link}"
  description = "Selflink for the GKE SubNetwork"
}

output "gke_cluster_pods_cidr" {
  value       = "${google_compute_subnetwork.gke.0.secondary_ip_range.ip_cidr_range}"
  description = "CIDR Range for Cluster Pods"
}

output "gke_cluster_services_cidr" {
  value       = "${google_compute_subnetwork.gke.1.secondary_ip_range.ip_cidr_range}"
  description = "CIDR Range for Cluster Services"
}

output "gke_cluster_master_cidr" {
  value       = "${google_container_cluster.primary.private_cluster_config.master_ipv4_cidr_block}"
  description = "CIDR Range for Cluster Master"
}
