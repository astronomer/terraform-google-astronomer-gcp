provider "aws" {
  version = "= 2.6.0"
  region  = "${var.aws_region}"
}

# Create the EKS cluster
module "eks" {
  source = "terraform-aws-modules/eks/aws"

  # version of the eks module to use
  version = "3.0.0"

  cluster_name    = "${local.cluster_name}"
  cluster_version = "${var.cluster_version}"

  subnets       = ["${module.vpc.private_subnets}"]
  tags          = "${local.tags}"
  vpc_id        = "${module.vpc.vpc_id}"
  worker_groups = "${local.worker_groups}"

  # We are not using the 'launch templates' feature at this time
  # this is a feature for deploying workers on Spot instances.
  # worker_groups_launch_template        = "${local.worker_groups_launch_template}"

  worker_additional_security_group_ids = ["${aws_security_group.all_worker_mgmt.id}"]
  map_roles = [
    {
      role_arn = "${aws_iam_role.kube_admin.arn}"
      username = "astronomer_kube_admin_role"
      group    = "system:masters"
    },
  ]
  map_accounts                    = "${var.map_accounts}"
  map_users                       = []
  cluster_endpoint_private_access = "true"

  # For now, the strategy is to leave the management API public
  # this way the whole thing can be deployed from remote node, then we just
  # disable the public endpoint and then everything is private.

  cluster_endpoint_public_access = "${var.management_api == "public" ? true : false}"
  map_roles_count                = "1"
  map_users_count                = "0"
  map_accounts_count             = "${var.map_accounts_count}"
  # TODO: check later for solution or better option
  # There is a terraform 'gotcha' - does not work to
  # do "${length(var.my_list)}" to get a "number" type
  worker_group_count = "2"
  worker_group_launch_template_count = "0"
}

resource "aws_security_group_rule" "bastion_connection_to_private_kube_api" {
  description       = "Connect the bastion to the EKS private endpoint"
  security_group_id = "${module.eks.cluster_security_group_id}"

  cidr_blocks = ["${aws_instance.bastion.private_ip}/32"]
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  type        = "ingress"
}

/*
resource "aws_security_group" "cluster" {
  name_prefix = "${local.cluster_name}"
  description = "Astronomer EKS cluster security group."
  vpc_id      = "${module.vpc.vpc_id}"
  tags        = "${merge(local.tags, map("Name", "${var.cluster_name}-eks_cluster_sg"))}"
}

resource "aws_security_group_rule" "cluster_egress_internet" {
  count             = "${var.cluster_create_security_group ? 1 : 0}"
  description       = "Allow cluster egress access to the Internet."
  protocol          = "-1"
  security_group_id = "${aws_security_group.cluster.id}"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  to_port           = 0
  type              = "egress"
}
*/

resource "local_file" "kubeconfig" {
  content  = "${module.eks.kubeconfig}"
  filename = "./kubeconfig"
}
