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
#!/bin/bash -xe
mkdir -p /opt/kubeconfig
mkdir -p /opt/astronomer

apt-get -y update;
apt-get -y install postgresql-client unzip;
snap install kubectl --classic;
snap install helm --classic

# Install Terraform
mkdir -p /opt/terraform_install
cd /opt/terraform_install
wget https://releases.hashicorp.com/terraform/${var.bastion_terraform_version}/terraform_${var.bastion_terraform_version}_linux_amd64.zip
unzip terraform_${var.bastion_terraform_version}_linux_amd64.zip
mv terraform /usr/local/bin/
EOF
}

resource "local_file" "client_certificate" {
  content  = "${google_container_cluster.primary.master_auth.0.client_certificate}"
  filename = "${path.module}/kubeconfig/client_certificate.pem"
}

resource "local_file" "client_key" {
  content  = "${google_container_cluster.primary.master_auth.0.client_key}"
  filename = "${path.module}/kubeconfig/client_key.pem"
}

resource "local_file" "cluster_ca_certificate" {
  content  = "${google_container_cluster.primary.master_auth.0.cluster_ca_certificate}"
  filename = "${path.module}/kubeconfig/cluster_ca_certificate.pem"
}

resource "null_resource" "astronomer_prepare" {
  depends_on = ["local_file.client_certificate",
    "local_file.client_key",
    "local_file.cluster_ca_certificate",
  ]

  provisioner "local-exec" {
    working_dir = "${path.module}"

    command = <<EOS
    ZONE="${google_compute_instance.bastion.zone}"
    NAME="${google_compute_instance.bastion.name}"
    # grant current user permissions for /opt,
    # copy the files over,
    # then switch it back to root
    gcloud beta compute ssh --zone $ZONE $NAME -- 'export MYUSER=$(whoami); sudo -E chown -R $MYUSER /opt/' && \
    gcloud beta compute scp --recurse ${path.module}/kubeconfig root@$NAME:/opt/ --zone $ZONE && \
    gcloud beta compute ssh --zone $ZONE $NAME -- 'sudo chown -R root:root /opt/'
    EOS
  }
}
