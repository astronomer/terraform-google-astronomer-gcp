/*
 Create VPC with public and
 private subnets
*/

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "1.14.0"

  name = "${var.base_name}-${var.environment}-vpc"

  cidr = "10.0.0.0/16"

  azs = "${local.azs}"

  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.3.0/24", "10.0.4.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = "${local.tags}"

  public_subnet_tags = {
    "${var.cluster_type == "private" ? "bastion_subnet" : format("%s", "kubernetes.io/cluster/${local.cluster_name}")}" = "${var.cluster_type == "private" ? "1" : "shared"}"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
  }

  vpc_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
  }
}

resource "aws_security_group" "worker_group_mgmt_one" {
  name_prefix = "worker_group_mgmt_one"
  description = "SG to be applied to all *nix machines"
  vpc_id      = "${module.vpc.vpc_id}"

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = [
      "10.0.0.0/8",
    ]
  }
}

resource "aws_security_group" "worker_group_mgmt_two" {
  name_prefix = "worker_group_mgmt_two"
  vpc_id      = "${module.vpc.vpc_id}"

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = [
      "192.168.0.0/16",
    ]
  }
}

resource "aws_security_group" "all_worker_mgmt" {
  name_prefix = "all_worker_management"
  vpc_id      = "${module.vpc.vpc_id}"

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = [
      "10.0.0.0/8",
      "172.16.0.0/12",
      "192.168.0.0/16",
    ]
  }
}
