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
  key_name   = "bastion_ssh_key"
  public_key = "${file("~/.ssh/id_rsa.pub")}"
}

resource "aws_instance" "bastion" {
  ami = "${data.aws_ami.ubuntu.id}"

  key_name = "${aws_key_pair.bastion_ssh_key.key_name}"

  instance_type = "t2.micro"

  subnet_id = "${module.vpc.public_subnets[0]}"

  vpc_security_group_ids = ["${aws_security_group.bastion_sg.id}"]

  tags = "${local.tags}"
}
