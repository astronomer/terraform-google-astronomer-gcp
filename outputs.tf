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
  value     = tls_private_key.cert_private_key.private_key_pem
  sensitive = true
}

output "tls_cert" {
  value = <<EOF
${acme_certificate.lets_encrypt.certificate_pem}
${acme_certificate.lets_encrypt.issuer_pem}
EOF
  sensitive = true
}

output "kubeconfig" {
  value = local.kubeconfig
  sensitive = true
}

output "kubeconfig_filename" {
  value = local_file.kubeconfig.filename
}

output "container_registry_bucket_name" {
  value = google_storage_bucket.container_registry.name
  description = "Cloud Storage Bucket Name to be used for Container Registry"
}

