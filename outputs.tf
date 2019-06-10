output "bastion_proxy_command" {
  value = "gcloud beta compute ssh --zone ${google_compute_instance.bastion.zone} ${google_compute_instance.bastion.name} --tunnel-through-iap --ssh-flag='-L 1234:127.0.0.1:8888 -C -N'"
}

output "kubernetes_api_sample_command" {
  value = "If you have started the api proxy using the bastion SOCKS5 proxy command, this should work:\nhttps_proxy=http://127.0.0.1:1234 kubectl get pods"
}

output "db_connection_string" {
  value     = "postgres://${google_sql_user.airflow.name}:${local.postgres_airflow_password}@${google_sql_database_instance.instance.private_ip_address}:5432"
  sensitive = true
}

output "base_domain" {
  value = local.base_domain
}

output "tls_key" {
  value     = acme_certificate.lets_encrypt.private_key_pem
  sensitive = true
}

output "tls_cert" {
  value     = acme_certificate.lets_encrypt.certificate_pem
  sensitive = true
}

output "kubeconfig" {
  value = <<EOF
apiVersion: v1
clusters:
- cluster:
    server: https://${google_container_cluster.primary.endpoint}
    certificate-authority-data: ${google_container_cluster.primary.master_auth[0].cluster_ca_certificate}
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
- name: "${google_container_cluster.primary.master_auth[0].username}"
  user:
    password: "${google_container_cluster.primary.master_auth[0].password}"
    username: "${google_container_cluster.primary.master_auth[0].username}"
EOF


  sensitive = true
}

output "container_registry_bucket_name" {
  value = google_storage_bucket.container_registry.name
  description = "Cloud Storage Bucket Name to be used for Container Registry"
}

