resource "random_string" "cloud_sql_name" {
  length  = 8
  upper   = false
  special = false
}

resource "google_sql_database_instance" "instance" {
  name             = "${random_string.cloud_sql_name.result}-astro-db"
  project          = "${var.project}"
  region           = "${var.region}"
  database_version = "POSTGRES_9_6"

  depends_on = [
    "google_service_networking_connection.private_vpc_connection",
  ]

  settings {
    tier              = "db-f1-micro"
    availability_type = "REGIONAL"

    ip_configuration {
      ipv4_enabled    = "false"
      private_network = "${google_compute_network.core.self_link}"
    }
  }
}

resource "random_string" "postgres_airflow_password" {
  count   = "${ var.postgres_airflow_password == "" ? 1 : 0 }"
  length  = 8
  special = false
}

resource "google_sql_user" "airflow" {
  name     = "airflow"
  instance = "${google_sql_database_instance.instance.name}"
  password = "${local.postgres_airflow_password}"
}
