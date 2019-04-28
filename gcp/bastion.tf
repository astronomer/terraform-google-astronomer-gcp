# Bastion host
resource "google_compute_instance" "bastion" {
  name         = "bastion"
  machine_type = "${var.machine_type}"
  zone         = "${var.zone}"
  project      = "${var.project}"

  boot_disk {
    initialize_params {
      image = "ubuntu-1804-bionic-v20190404"
    }
  }

  network_interface {
    subnetwork = "${google_compute_subnetwork.bastion.self_link}"
  }

  service_account {
    email  = "${google_service_account.bastion.email}"
    scopes = ["cloud-platform"]
  }

  metadata {
    block-project-ssh-keys = "true"
    enable-oslogin         = "true"
  }

  allow_stopping_for_update = true

  metadata_startup_script = <<EOF
sudo apt-get -y update;
sudo apt-get -y install postgresql-client;
sudo snap install kubectl --classic
EOF
}
