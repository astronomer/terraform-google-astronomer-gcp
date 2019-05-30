data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

provider "http" {
  version = "1.1"
}

data "http" "local_ip" {
  url = "http://ipv4.icanhazip.com/s"
}

resource "aws_security_group" "bastion_sg" {
  name        = "astronomer_bastion_sg"
  description = "Allow SSH inbound traffic"
  vpc_id      = "${module.vpc.vpc_id}"

  ingress {
    # TLS (change to whatever ports you need)
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    # Please restrict your ingress to only necessary IPs and ports.
    cidr_blocks = ["${trimspace(data.http.local_ip.body)}/32"]
  }

  egress {
    # TLS (change to whatever ports you need)
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${local.tags}"
}

resource "aws_key_pair" "bastion_ssh_key" {
  key_name   = "bastion_ssh_key_${var.customer_id}"
  public_key = "${file("~/.ssh/id_rsa.pub")}"
}

resource "aws_instance" "bastion" {
  depends_on = ["module.eks"]

  ami = "${data.aws_ami.ubuntu.id}"

  iam_instance_profile = "${aws_iam_instance_profile.bastion_instance_profile.name}"

  key_name = "${aws_key_pair.bastion_ssh_key.key_name}"

  instance_type = "t2.micro"

  subnet_id = "${module.vpc.public_subnets[0]}"

  vpc_security_group_ids = ["${aws_security_group.bastion_sg.id}"]

  tags = "${local.tags}"
}

# managed separately so the bastion doesn't need to
# redeploy during development
resource "null_resource" "bastion_setup" {
  # this makes this resource run each time
  triggers {
    build_number = "${timestamp()}"
  }

  connection {
    type        = "ssh"
    host        = "${aws_instance.bastion.public_ip}"
    user        = "ubuntu"
    private_key = "${file("~/.ssh/id_rsa")}"
    port        = "22"
  }

  # Using terraform provisioner instead of UserData
  # in order to avoid a race condition. Provisioners
  # are executed sequentally, in order top to bottom.
  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /opt/terraform_install",
      "sudo mkdir -p /opt/db_password",
      "sudo mkdir -p /opt/tls_secrets",
      "sudo mkdir -p /opt/astronomer",
      "sudo chown -R ubuntu:ubuntu /opt",
      "sudo apt-get -y update;",
      "sudo apt-get -y install postgresql-client unzip",
      "sudo snap install kubectl --classic",
      "sudo snap install helm --classic",
      "sudo snap install aws-cli --classic",
    ]
  }

  # this is separate from the above in order to load a new shell
  # so that unzip is present in the PATH
  provisioner "remote-exec" {
    inline = [
      "rm /opt/terraform_install/*",
      "cd /opt/terraform_install && wget https://releases.hashicorp.com/terraform/${var.bastion_terraform_version}/terraform_${var.bastion_terraform_version}_linux_amd64.zip && sudo unzip terraform_${var.bastion_terraform_version}_linux_amd64.zip && sudo mv terraform /usr/local/bin/",
      "cd /usr/local/bin && sudo curl -o aws-iam-authenticator https://amazon-eks.s3-us-west-2.amazonaws.com/1.12.7/2019-03-27/bin/linux/amd64/aws-iam-authenticator && sudo chmod +x aws-iam-authenticator",
    ]
  }

  provisioner "file" {
    content     = "postgres://${module.aurora.this_rds_cluster_master_username}:${module.aurora.this_rds_cluster_master_password}@${module.aurora.this_rds_cluster_endpoint}:${module.aurora.this_rds_cluster_port}"
    destination = "/opt/db_password/connection_string"
  }

  provisioner "file" {
    content     = "${acme_certificate.lets_encrypt.certificate_pem}"
    destination = "/opt/tls_secrets/tls.crt"
  }

  provisioner "file" {
    content     = "${acme_certificate.lets_encrypt.private_key_pem}"
    destination = "/opt/tls_secrets/tls.key"
  }

  provisioner "file" {
    source      = "${path.module}/../astronomer"
    destination = "/opt"
  }

  provisioner "file" {
    content     = "${module.eks.kubeconfig}"
    destination = "/opt/astronomer/kubeconfig"
  }

  # TODO: avoid the need to provision with public API, then disable
  # the IAM user that calls the eks module is the only master user
  # and has to perform the configmap update before the bastion
  # is authorized

  provisioner "local-exec" {
    working_dir = "${path.module}"

    command = <<EOS
    kubectl apply -f config-map-aws-auth_${local.cluster_name}.yaml --kubeconfig ${module.eks.kubeconfig_filename}
    EOS
  }

  /*
  provisioner "local-exec" {
    working_dir = "${path.module}"

    command = <<EOS
    CLUSTER_ENDPOINT=${replace(module.eks.cluster_endpoint,"https://","")}
    echo "127.0.0.1 $CLUSTER_ENDPOINT" >> /etc/hosts
    # this background process is automatically killed when the local-exec shell quits
    ssh -o StrictHostKeyChecking=no -N -L 443:$CLUSTER_ENDPOINT:443 ubuntu@${aws_instance.bastion.public_ip} &
    kubectl apply -f config-map-aws-auth_${local.cluster_name}.yaml --kubeconfig ${module.eks.kubeconfig_filename}
    EOS
  }
  */
}

resource "local_file" "turn_off_strict_host_checking" {
  content = <<EOF
Host *
    StrictHostKeyChecking no
EOF

  filename = "/tmp/sshconfig_no_checking"
}

resource "null_resource" "astronomer_prepare" {
  depends_on = ["null_resource.bastion_setup",
    "local_file.turn_off_strict_host_checking",
    "aws_security_group_rule.bastion_connection_to_private_kube_api",
    "module.aurora",
  ]

  # this makes this resource run each time
  triggers {
    build_number = "${timestamp()}"
  }

  connection {
    type        = "ssh"
    host        = "${aws_instance.bastion.public_ip}"
    user        = "ubuntu"
    private_key = "${file("~/.ssh/id_rsa")}"
    port        = "22"
  }

  provisioner "file" {
    content = <<EOF
base_domain  = "${var.customer_id}.${var.route53_domain}"
cluster_type = "${var.cluster_type}"
admin_email  = "${var.admin_email}"
EOF

    destination = "/opt/astronomer/terraform.tfvars"
  }

  provisioner "remote-exec" {
    inline = [<<EOF
#!/bin/bash
export KUBECONFIG=./kubeconfig;
cd /opt/astronomer;
/snap/bin/kubectl create serviceaccount --namespace kube-system tiller
/snap/bin/kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
/snap/bin/kubectl patch deploy --namespace kube-system tiller-deploy -p '{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}'
/snap/bin/helm init --service-account tiller --upgrade
EOF
    ]
  }

  provisioner "local-exec" {
    command = "py.test --host='ssh://ubuntu@${aws_instance.bastion.public_ip}:22' --ssh-config=/tmp/sshconfig_no_checking ../test_bastion.py"
  }
}

resource "null_resource" "astronomer_deploy" {
  depends_on = ["null_resource.astronomer_prepare"]

  connection {
    type        = "ssh"
    host        = "${aws_instance.bastion.public_ip}"
    user        = "ubuntu"
    private_key = "${file("~/.ssh/id_rsa")}"
    port        = "22"
  }

  provisioner "remote-exec" {
    inline = [<<EOF
#!/bin/bash
export KUBECONFIG=./kubeconfig;
cd /opt/astronomer;
terraform init;
terraform apply --auto-approve;
EOF
    ]
  }

  provisioner "remote-exec" {
    when = "destroy"

    inline = [<<EOF
#!/bin/bash
export KUBECONFIG=./kubeconfig;
cd /opt/astronomer;
terraform destroy --auto-approve;
EOF
    ]
  }
}
