output "bastion_proxy_command" {
  value = "gcloud beta compute ssh --zone ${google_compute_instance.bastion[0].zone} ${google_compute_instance.bastion[0].name} --tunnel-through-iap --ssh-flag='-L 1234:127.0.0.1:8888 -C -N'"
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

# https://github.com/hashicorp/terraform/issues/1178
resource "null_resource" "dependency_setter" {
  depends_on = [google_container_cluster.primary,
    google_container_node_pool.node_pool_mt,
    google_container_node_pool.node_pool_platform,
  acme_certificate.lets_encrypt]

  provisioner "local-exec" {
    # wait 10 minutes after the first
    # deployment to allow GKE auto-updates
    # to converge
    command = "sleep ${var.wait_for}"
  }
}

output "depended_on" {
  value = "${null_resource.dependency_setter.id}-${timestamp()}"
}

output "gcp_default_service_account_key" {
  value = "${base64decode(google_service_account_key.default_key.private_key)}"
  sensitive = true
}

output "load_balancer_ip" {
  value = google_compute_address.nginx_static_ip.address
}
