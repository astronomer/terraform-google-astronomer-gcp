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

resource "local_file" "kubeconfig" {
  sensitive_content = <<EOF
apiVersion: v1
clusters:
- cluster:
    server: https://${google_container_cluster.primary.endpoint}
    certificate-authority-data: ${google_container_cluster.primary.master_auth.0.cluster_ca_certificate}
  name: cluster
contexts:
- context:
    cluster: cluster
    user: admin
  name: context
current-context: "context"
kind: Config
preferences: {}
users:
- name: admin
  user:
    password: "${google_container_cluster.primary.master_auth.0.password}"
    username: admin
EOF

  filename = "${path.module}/kubeconfig"
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
  config_path = "/opt/astronomer/kubeconfig"
  load_config_file = true
}

provider "helm" {
  service_account = "tiller"
  debug           = true

  kubernetes {
    config_path = "/opt/astronomer/kubeconfig"
    load_config_file = true
  }
}
EOF

  filename = "/tmp/providers.tf.bastion"
}

resource "null_resource" "astronomer_prepare" {
  depends_on = [
    "local_file.kubeconfig",
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
    gcloud beta compute scp ${path.module}/kubeconfig $NAME:/opt/astronomer/kubeconfig --zone $ZONE && \
    gcloud beta compute scp --recurse ${path.module}/tls_secrets $NAME:/opt --zone $ZONE && \
    gcloud beta compute scp --recurse ${path.module}/db_password $NAME:/opt --zone $ZONE && \
    gcloud beta compute scp /tmp/providers.tf.bastion $NAME:/opt/astronomer/providers.tf --zone $ZONE && \
    gcloud beta compute scp ${path.module}/files/prepare_k8.sh $NAME:/opt/astronomer/prepare_k8.sh --zone $ZONE && \
    gcloud beta compute scp ${path.module}/files/rbac-config.yaml $NAME:/opt/astronomer/rbac-config.yaml --zone $ZONE && \
    gcloud beta compute ssh --zone $ZONE $NAME -- "sudo chmod +x /opt/astronomer/prepare_k8.sh"
    gcloud beta compute ssh --zone $ZONE $NAME -- "cd /opt/astronomer && sudo KUBECONFIG=./kubeconfig ./prepare_k8.sh"
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
    gcloud beta compute scp --recurse ${path.module}/../astronomer $NAME:/opt --zone $ZONE && \
    gcloud beta compute ssh --zone $ZONE $NAME -- 'cd /opt/astronomer && sudo terraform init' && \
    gcloud beta compute ssh --zone $ZONE $NAME -- 'cd /opt/astronomer && sudo terraform apply -var cluster_type=public -var enable_istio=${var.enable_istio} -var base_domain="astro.${var.google_domain}" -var admin_email="${var.bastion_admin_emails[0]}" -var load_balancer_ip=${google_compute_address.nginx_address.address} --auto-approve'
    EOS
  }

  provisioner "local-exec" {
    when = "destroy"

    command = <<EOF
    gcloud beta compute ssh --zone $ZONE $NAME -- 'cd /opt/astronomer && sudo terraform destroy -var cluster_type=public -var base_domain="astro.${var.google_domain}" -var admin_email="${var.bastion_admin_emails[0]}" -var load_balancer_ip=${google_compute_address.nginx_address.address} --auto-approve'
    EOF
  }
}
