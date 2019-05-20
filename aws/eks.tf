terraform {
  required_version = ">= 0.11.8"
}

provider "aws" {
  version = "= 2.6.0"
  region  = "${var.aws_region}"
}

provider "random" {
  version = "= 1.3.1"
}

resource "random_string" "suffix" {
  length  = 8
  special = false
}

locals {

  cluster_name = "${var.base_name}-cluster-${random_string.suffix.result}"

  azs = ["${var.aws_region}a", "${var.aws_region}b"]

  worker_groups = [
    {
      instance_type        = "${var.worker_instance_type}"
      subnets              = "${join(",", module.vpc.private_subnets)}"
      additional_userdata  = "echo 'hello world!'"
      asg_desired_capacity = "${var.min_cluster_size}"
      asg_min_size         = "${var.min_cluster_size}"
      asg_max_size         = "${var.max_cluster_size}"
    },
    {
      instance_type                 = "${var.lb_instance_type}"
      additional_userdata           = "echo 'hello world!'"
      subnets                       = "${join(",", module.vpc.private_subnets)}"
      additional_security_group_ids = "${aws_security_group.worker_group_mgmt_one.id},${aws_security_group.worker_group_mgmt_two.id}"
      asg_desired_capacity = "2"
      asg_min_size         = "2"
      asg_max_size         = "${var.max_cluster_size}"
    },
  ]

  tags = {
    Environment = "${var.environment}"
    Owner = "${var.owner}"
  }
}

/*
 Create VPC with public and
 private subnets
*/

module "vpc" {

  source = "terraform-aws-modules/vpc/aws"
  version = "1.14.0"

  name = "${var.base_name}-${var.environment}-vpc"

  cidr = "10.0.0.0/16"

  azs = "${local.azs}"

  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets     = ["10.0.3.0/24", "10.0.4.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  tags               = "${local.tags}"

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

/*
Create the EKS cluster
*/

module "eks" {

  source                               = "terraform-aws-modules/eks/aws"

  # version of the eks module to use
  version                              = "3.0.0"

  cluster_name                         = "${local.cluster_name}"
  cluster_version                      = "${var.cluster_version}"

  subnets                              = ["${module.vpc.private_subnets}"]
  tags                                 = "${local.tags}"
  vpc_id                               = "${module.vpc.vpc_id}"
  worker_groups                        = "${local.worker_groups}"

  # We are not using the 'launch templates' feature at this time
  # this is a feature for deploying workers on Spot instances.
  # worker_groups_launch_template        = "${local.worker_groups_launch_template}"

  worker_additional_security_group_ids = ["${aws_security_group.all_worker_mgmt.id}"]

  map_roles                            = "${var.map_roles}"
  map_accounts                         = "${var.map_accounts}"
  map_users                            = "${var.map_users}"

  cluster_endpoint_private_access      = "${var.cluster_type == "private" ? true : false}"

  /*
  For now, the strategy is to leave the management API public
  this way the whole thing can be deployed from remote node, then we just
  disable the public endpoint and then everything is private.
  */
  cluster_endpoint_public_access     = "${var.management_api == "public" ? true : false}"

  map_roles_count                      = "${var.map_roles_count}"
  map_users_count                      = "${var.map_users_count}"
  map_accounts_count                   = "${var.map_accounts_count}"

  /*
  TODO: check later for solution or better option
  There is a terraform 'gotcha' - does not work to
  do "${length(var.my_list)}" to get a "number" type
  */
  worker_group_count                   = "2"
  worker_group_launch_template_count   = "0"
}

resource "local_file" "kubeconfig" {
    content     = "${module.eks.kubeconfig}"
    filename = "./kubeconfig"
}
