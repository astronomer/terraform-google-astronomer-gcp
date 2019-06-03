/*
 Create VPC with public and
 private subnets
*/

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "1.14.0"

  name = "astronomer-${var.customer_id}-${var.environment}-vpc"

  cidr = "10.${var.ten_dot_what_cidr}.0.0/16"

  azs = "${local.azs}"

  private_subnets  = ["10.${var.ten_dot_what_cidr}.1.0/24", "10.${var.ten_dot_what_cidr}.2.0/24"]
  public_subnets   = ["10.${var.ten_dot_what_cidr}.3.0/24", "10.${var.ten_dot_what_cidr}.4.0/24"]
  database_subnets = ["10.${var.ten_dot_what_cidr}.5.0/24", "10.${var.ten_dot_what_cidr}.6.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  # "
  # When you enable endpoint private access for your cluster, Amazon EKS creates
  # a Route 53 private hosted zone on your behalf and associates it with your
  # cluster's VPC. This private hosted zone is managed by Amazon EKS, and it doesn't
  # appear in your account's Route 53 resources. In order for the private hosted zone
  # to properly route traffic to your API server, your VPC must have enableDnsHostnames
  # and enableDnsSupport set to true
  # "
  # copied from (5/21/19):
  # https://docs.aws.amazon.com/eks/latest/userguide/cluster-endpoint.html
  enable_dns_hostnames = true

  enable_dns_support = true

  tags = "${local.tags}"

  public_subnet_tags = {
    "${var.cluster_type == "private" ? "bastion_subnet" : format("%s", "kubernetes.io/cluster/${local.cluster_name}")}" = "${var.cluster_type == "private" ? "1" : "shared"}"
  }

  /*
  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
  }
  */

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
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
