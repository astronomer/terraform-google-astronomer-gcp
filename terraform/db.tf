resource "random_id" "db_name_suffix" {
  byte_length = 4
}

resource "google_service_account" "cloud_sql_admin" {
  account_id   = "${var.deployment_id}-cloud-sql-admin"
  display_name = "Cloud SQL Admin for ${var.deployment_id}"
}

resource "google_project_iam_member" "project" {
  project = local.project
  role    = "roles/cloudsql.admin"
  member  = "serviceAccount:${google_service_account.cloud_sql_admin.email}"
}

resource "google_service_account_key" "cloud_sql_admin" {
  service_account_id = google_service_account.cloud_sql_admin.name
}

resource "google_sql_database_instance" "instance" {
  count = var.deploy_db ? 1 : 0

  deletion_protection = var.db_deletion_protection

  name             = "${var.deployment_id}-astro-db-${random_id.db_name_suffix.hex}"
  region           = local.region
  database_version = var.db_version
  depends_on       = [google_service_networking_connection.private_vpc_connection]

  settings {
    tier              = var.cloud_sql_tier
    availability_type = var.cloud_sql_availability_type

    ip_configuration {
      ipv4_enabled    = "false"
      private_network = google_compute_network.core.self_link
    }

    insights_config {
      query_insights_enabled = true
      query_string_length    = 2048
      record_client_address  = true
      record_application_tags = true
    }


    backup_configuration {
      enabled            = true
      binary_log_enabled = (local.db_engine == "mysql") ? true : false
    }

    dynamic "database_flags" {
      for_each = var.db_max_connections > 0 ? ["placeholder"] : []
      content {
        name  = "max_connections"
        value = var.db_max_connections
      }
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
  count           = var.deploy_db ? 1 : 0
  name            = "airflow"
  deletion_policy = "ABANDON"
  instance        = google_sql_database_instance.instance[0].name
  password        = local.postgres_airflow_password
}
