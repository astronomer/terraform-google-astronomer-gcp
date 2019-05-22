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
  key_name   = "bastion_ssh_key_${var.label}"
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
      "sudo mkdir -p /opt/astronomer_certs",
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
      "cd /opt/terraform_install && wget https://releases.hashicorp.com/terraform/${var.bastion_terraform_version}/terraform_${var.bastion_terraform_version}_linux_amd64.zip && sudo unzip terraform_${var.bastion_terraform_version}_linux_amd64.zip && sudo mv terraform /usr/local/bin/",
      "cd /usr/local/bin && sudo curl -o aws-iam-authenticator https://amazon-eks.s3-us-west-2.amazonaws.com/1.12.7/2019-03-27/bin/linux/amd64/aws-iam-authenticator && sudo chmod +x aws-iam-authenticator",
    ]
  }

  provisioner "file" {
    content     = "${acme_certificate.lets_encrypt.certificate_pem}"
    destination = "/opt/astronomer_certs/tls.crt"
  }

  provisioner "file" {
    content     = "${acme_certificate.lets_encrypt.private_key_pem}"
    destination = "/opt/astronomer_certs/tls.key"
  }

  provisioner "file" {
    content     = "${module.eks.kubeconfig}"
    destination = "/opt/astronomer/kubeconfig"
  }

  provisioner "file" {
    source      = "../astronomer"
    destination = "/opt"
  }

  # TODO: avoid the need to provision with public API, then disable
  # the IAM user that calls the eks module is the only master user
  # and has to perform the configmap update before the bastion
  # is authorized

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

resource "null_resource" "astronomer_prepare" {
  depends_on = ["null_resource.bastion_setup",
    "aws_security_group_rule.bastion_connection_to_private_kube_api",
  ]

  connection {
    type        = "ssh"
    host        = "${aws_instance.bastion.public_ip}"
    user        = "ubuntu"
    private_key = "${file("~/.ssh/id_rsa")}"
    port        = "22"
  }

  provisioner "file" {
    content = <<EOF
base_domain  = "astro.${var.route53_domain}"
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
/snap/bin/helm init;
EOF
    ]
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
}
