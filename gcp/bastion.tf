# Bastion host
resource "google_compute_instance" "bastion" {
  name         = "bastion"
  machine_type = "${var.machine_type}"
  zone         = "${var.zone}"

  boot_disk {
    initialize_params {
      image = "ubuntu-1804-bionic-v20190404"
    }
  }

  network_interface {
    subnetwork = "default"

    access_config {
      # Ephemeral IP - leaving this block empty will generate a new external IP and assign it to the machine
    }
  }

  service_account {
    email  = "${google_service_account.read-only.email}"
    scopes = ["cloud-platform"]
  }

  tags = ["bastion"]
}
