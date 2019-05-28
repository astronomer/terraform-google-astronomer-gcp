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

/*
resource "local_file" "client_certificate" {
  sensitive_content  = "${google_container_cluster.primary.master_auth.0.client_certificate}"
  filename = "${path.module}/kubeconfig/client_certificate.pem"
  # Only available on first run
  lifecycle {
    ignore_changes = ["sensitive_content"]
  }
}

resource "local_file" "client_key" {
  sensitive_content  = "${google_container_cluster.primary.master_auth.0.client_key}"
  filename = "${path.module}/kubeconfig/client_key.pem"
  # Only available on first run
  lifecycle {
    ignore_changes = ["sensitive_content"]
  }
}
*/

resource "local_file" "k8_admin_password" {
  sensitive_content = "${google_container_cluster.primary.master_auth.0.password}"
  filename          = "${path.module}/kubeconfig/admin_password"

  # Only available on first run
  lifecycle {
    ignore_changes = ["sensitive_content"]
  }
}

resource "local_file" "client_certificate" {
  sensitive_content = "${google_container_cluster.primary.master_auth.0.client_certificate}"
  filename          = "${path.module}/kubeconfig/client_certificate.pem"

  # Only available on first run
  lifecycle {
    ignore_changes = ["sensitive_content"]
  }
}

resource "local_file" "client_key" {
  sensitive_content = "${google_container_cluster.primary.master_auth.0.client_key}"
  filename          = "${path.module}/kubeconfig/client_key.pem"

  # Only available on first run
  lifecycle {
    ignore_changes = ["sensitive_content"]
  }
}

resource "local_file" "cluster_ca_certificate" {
  sensitive_content = "${base64decode(google_container_cluster.primary.master_auth.0.cluster_ca_certificate)}"
  filename          = "${path.module}/kubeconfig/cluster_ca_certificate.pem"
}

resource "local_file" "tls_key" {
  sensitive_content = "${acme_certificate.lets_encrypt.private_key_pem}"
  filename          = "${path.module}/tls_secrets/tls.key"
}

resource "local_file" "tls_cert" {
  sensitive_content = "${acme_certificate.lets_encrypt.certificate_pem}"
  filename          = "${path.module}/tls_secrets/tls.crt"
}

resource "local_file" "db_password" {
  sensitive_content = "postgres://${google_sql_user.airflow.name}:${local.postgres_airflow_password}@${google_sql_database_instance.instance.private_ip_address}:5432"
  filename          = "${path.module}/db_password/connection_string"
}

resource "local_file" "bastion_providers" {
  content = <<EOF
provider "kubernetes" {
  host                   = "https://${google_container_cluster.primary.endpoint}"
  # client_certificate     = "$${file("/opt/kubeconfig/client_certificate.pem")}"
  # client_key             = "$${file("/opt/kubeconfig/client_key.pem")}"
  cluster_ca_certificate = "$${file("/opt/kubeconfig/cluster_ca_certificate.pem")}"
  username = "admin"
  password = "$${file("/opt/kubeconfig/admin_password")}"
  load_config_file = false
}

provider "helm" {
  service_account = "tiller"
  debug           = true

  kubernetes {
    host                   = "https://${google_container_cluster.primary.endpoint}"
    # client_certificate     = "$${file("/opt/kubeconfig/client_certificate.pem")}"
    # client_key             = "$${file("/opt/kubeconfig/client_key.pem")}"
    cluster_ca_certificate = "$${file("/opt/kubeconfig/cluster_ca_certificate.pem")}"
    username = "admin"
    password = "$${file("/opt/kubeconfig/admin_password")}"
  }
}
EOF

  filename = "/tmp/providers.tf.bastion"
}

resource "null_resource" "astronomer_prepare" {
  depends_on = [
    #"local_file.client_certificate",
    #"local_file.client_key",
    "local_file.k8_admin_password",

    "local_file.cluster_ca_certificate",
    "local_file.bastion_providers",
    "local_file.tls_key",
    "local_file.tls_cert",
    "local_file.db_password",
  ]

  provisioner "local-exec" {
    working_dir = "${path.module}"

    command = <<EOS
    ZONE="${google_compute_instance.bastion.zone}"
    NAME="${google_compute_instance.bastion.name}"
    # grant current user permissions for /opt,
    # copy the files over,
    # then switch it back to root
    gcloud beta compute ssh --zone $ZONE $NAME -- 'sudo mkdir /opt || true'
    gcloud beta compute ssh --zone $ZONE $NAME -- 'export MYUSER=$(whoami); sudo -E chown -R $MYUSER /opt' && \
    gcloud beta compute scp --recurse ${path.module}/kubeconfig $NAME:/opt --zone $ZONE && \
    gcloud beta compute scp --recurse ${path.module}/tls_secrets $NAME:/opt --zone $ZONE && \
    gcloud beta compute scp --recurse ${path.module}/db_password $NAME:/opt --zone $ZONE && \
    gcloud beta compute scp --recurse ${path.module}/../astronomer $NAME:/opt --zone $ZONE && \
    gcloud beta compute scp /tmp/providers.tf.bastion $NAME:/opt/astronomer/providers.tf --zone $ZONE && \
    gcloud beta compute ssh --zone $ZONE $NAME -- 'sudo chown -R root:root /opt'
    EOS
  }
}

resource "null_resource" "astronomer_deploy" {
  depends_on = [
    "null_resource.astronomer_prepare",
  ]

  provisioner "local-exec" {
    working_dir = "${path.module}"

    command = <<EOS
    ZONE="${google_compute_instance.bastion.zone}"
    NAME="${google_compute_instance.bastion.name}"
    gcloud beta compute ssh --zone $ZONE $NAME -- 'sudo terraform init /opt/astronomer'
    gcloud beta compute ssh --zone $ZONE $NAME -- 'sudo terraform apply -var base_domain="astro.${var.google_domain}" -var admin_email="${var.bastion_admin_emails[0]}" --auto-approve /opt/astronomer'
    EOS
  }
}
