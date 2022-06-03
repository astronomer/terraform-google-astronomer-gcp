output "cluster_name" {
  description = "cluster name"
  value       = local.cluster_name
}

output "endpoint" {
  sensitive   = true
  description = "cluster endpoint"
  value       = local.endpoint
}

output "ca_certificate" {
  sensitive = true
  value     = local.cluster_ca_certificate
}

output "bastion_proxy_command" {
  value = length(google_compute_instance.bastion) > 0 ? "gcloud beta compute ssh --zone ${element(concat(google_compute_instance.bastion.*.zone, list("")), 0)} ${element(concat(google_compute_instance.bastion.*.name, list("")), 0)} --tunnel-through-iap --ssh-flag='-L 1234:127.0.0.1:8888 -C -N'" : "Not applicable - no bastion"
}

output "db_connection_string" {
  value     = var.deploy_db ? "postgres://${element(concat(google_sql_user.airflow.*.name, list("")), 0)}:${local.postgres_airflow_password}@${element(concat(google_sql_database_instance.instance.*.private_ip_address, list("")), 0)}:5432" : "N/A: DB is not deployed with the terraform-google-astronomer-gcp module. Set deploy_db = true"
  sensitive = true
}

output "db_connection_user" {
  value = var.deploy_db ? element(concat(google_sql_user.airflow.*.name, list("")), 0) : "N/A"
}

output "db_connection_password" {
  value     = var.deploy_db ? local.postgres_airflow_password : "N/A"
  sensitive = true
}

output "db_instance_private_ip" {
  value = var.deploy_db ? element(concat(google_sql_database_instance.instance.*.private_ip_address, list("")), 0) : "N/A"
}

output "db_instance_name" {
  value = var.deploy_db ? element(concat(google_sql_database_instance.instance.*.name, list("")), 0) : "N/A"
}

output "base_domain" {
  value = local.base_domain
}

output "tls_key" {
  value     = var.lets_encrypt ? tls_private_key.cert_private_key.0.private_key_pem : ""
  sensitive = true
}

output "tls_cert" {
  value     = var.dns_managed_zone == "" ? "" : <<EOF
${acme_certificate.lets_encrypt[0].certificate_pem}
${acme_certificate.lets_encrypt[0].issuer_pem}
EOF
  sensitive = true
}

output "kubeconfig" {
  value     = local.kubeconfig
  sensitive = true
}

output "kubeconfig_filename" {
  value = local_sensitive_file.kubeconfig.filename
}

output "container_registry_bucket_name" {
  value       = google_storage_bucket.container_registry.name
  description = "Cloud Storage Bucket Name to be used for Container Registry"
}

# https://github.com/hashicorp/terraform/issues/1178
resource "null_resource" "dependency_setter" {
  depends_on = [google_container_cluster.primary,
    google_container_node_pool.node_pool_mt,
    google_container_node_pool.node_pool_mt_green,
    google_container_node_pool.node_pool_platform,
    google_container_node_pool.node_pool_platform_green,
    google_sql_database_instance.instance,
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

output "gcp_cloud_sql_admin_key" {
  value     = base64decode(google_service_account_key.cloud_sql_admin.private_key)
  sensitive = true
}

output "gcp_default_service_account_key" {
  value     = base64decode(google_service_account_key.default_key.private_key)
  sensitive = true
}

output "load_balancer_ip" {
  value = google_compute_address.nginx_static_ip.address
}

output "gcp_region" {
  value = local.region
}

output "gcp_project" {
  value = local.project
}

output "gcp_velero_backups_bucket_name" {
  value = google_storage_bucket.velero_k8s_backup.name
}

output "gcp_velero_service_account_email" {
  value = google_service_account.velero.email
}

output "gcp_velero_service_account_key" {
  value     = base64decode(google_service_account_key.velero.private_key)
  sensitive = true
}
