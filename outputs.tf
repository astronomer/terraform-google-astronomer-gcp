output "db_connection_string" {
  value = "postgres://${google_sql_user.airflow.name}:${local.postgres_airflow_password}@${google_sql_database_instance.instance.private_ip_address}:5432"
  sensitive = true
}

output "tls_key" {
  value = "${acme_certificate.lets_encrypt.private_key_pem}"
  sensitive = true
}

output "tls_cert" {
  value = "${acme_certificate.lets_encrypt.certificate_pem}"
  sensitive = true
}

output "kubeconfig" {
  value = <<EOF
apiVersion: v1
clusters:
- cluster:
    server: https://${google_container_cluster.primary.endpoint}
    certificate-authority-data: ${google_container_cluster.primary.master_auth.0.cluster_ca_certificate}
  name: cluster
contexts:
- context:
    cluster: cluster
    user: admin
  name: context
current-context: "context"
kind: Config
preferences: {}
users:
- name: "${google_container_cluster.primary.master_auth.0.username}"
  user:
    password: "${google_container_cluster.primary.master_auth.0.password}"
    username: "${google_container_cluster.primary.master_auth.0.username}"
EOF

  sensitive = true
}

output "container_registry_bucket_name" {
  value       = "${google_storage_bucket.container_registry.name}"
  description = "Cloud Storage Bucket Name to be used for Container Registry"
}
