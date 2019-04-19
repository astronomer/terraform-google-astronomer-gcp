resource "google_sql_database_instance" "instance" {
  name             = "cloud-sql-test"
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
      private_network = "${google_compute_network.default.self_link}"
    }
  }
}
