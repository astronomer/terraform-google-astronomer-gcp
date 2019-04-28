output "bastion_ip" {
  value = "${google_compute_instance.bastion.network_interface.0.network_ip}"
}

output "postgres_ip" {
  value = "${google_sql_database_instance.instance.ip_address.0.ip_address}"
}

output "postgres_user" {
  value = "${google_sql_user.airflow.name}"
}

output "postgres_password" {
  value = "${google_sql_user.airflow.password}"
}
