// Get Latest Ubuntu Lts Image for the bastion
data "google_compute_image" "ubuntu_lts_latest_image" {
  family  = "${var.bastion_image_family["name"]}"
  project = "${var.bastion_image_family["project"]}"
}

# Bastion host
resource "google_compute_instance" "bastion" {
  name         = "${local.bastion_name}"
  machine_type = "${var.machine_type_bastion}"
  zone         = "${var.zone}"

  boot_disk {
    initialize_params {
      image = "${data.google_compute_image.ubuntu_lts_latest_image.self_link}"
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
#!/bin/bash
apt-get -y update;
apt-get -y tinyproxy;
EOF
}
