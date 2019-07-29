resource "random_id" "db_name_suffix" {
  byte_length = 4
}

resource "google_service_account" "cloud_sql_admin" {
  account_id   = "${var.deployment_id}-cloud-sql-admin"
  display_name = "Cloud SQL Admin for ${var.deployment_id}"
}

resource "google_project_iam_binding" "project" {
  project = local.project
  role    = "roles/cloudsql.admin"

  members = [
    "serviceAccount:${google_service_account.cloud_sql_admin.email}",
  ]
}

resource "google_service_account_key" "cloud_sql_admin" {
  service_account_id = google_service_account.cloud_sql_admin.name
}

resource "google_sql_database_instance" "instance" {
  name             = "${var.deployment_id}-astro-db-${random_id.db_name_suffix.hex}"
  region           = local.region
  database_version = "POSTGRES_9_6"

  depends_on = [google_service_networking_connection.private_vpc_connection]

  settings {
    tier              = var.cloud_sql_tier
    availability_type = var.cloud_sql_availability_type

    ip_configuration {
      ipv4_enabled    = "false"
      private_network = google_compute_network.core.self_link
    }

    backup_configuration {
      enabled = true
    }
  }

  timeouts {
    create = "30m"
    delete = "30m"
  }

}

resource "random_string" "postgres_airflow_password" {
  count   = var.postgres_airflow_password == "" ? 1 : 0
  length  = 8
  special = false
}

resource "google_sql_user" "airflow" {
  name     = "airflow"
  instance = google_sql_database_instance.instance.name
  password = local.postgres_airflow_password
}
