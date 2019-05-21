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
      user_arn = "${aws_iam_user.kube_admin.arn}"
      username = "${aws_iam_user.kube_admin.name}"
      group    = "system:masters"
    },
  ]
  map_accounts = "${var.map_accounts}"
  map_users = [
    {
      user_arn = "${aws_iam_user.kube_admin.arn}"
      username = "${aws_iam_user.kube_admin.name}"
      group    = "system:masters"
    },
  ]
  cluster_endpoint_private_access = "${var.cluster_type == "private" ? true : false}"

  # For now, the strategy is to leave the management API public
  # this way the whole thing can be deployed from remote node, then we just
  # disable the public endpoint and then everything is private.

  cluster_endpoint_public_access = "${var.management_api == "public" ? true : false}"
  map_roles_count                = "1"
  map_users_count                = "1"
  map_accounts_count             = "${var.map_accounts_count}"
  # TODO: check later for solution or better option
  # There is a terraform 'gotcha' - does not work to
  # do "${length(var.my_list)}" to get a "number" type
  worker_group_count = "2"
  worker_group_launch_template_count = "0"
}

resource "local_file" "kubeconfig" {
  content  = "${module.eks.kubeconfig}"
  filename = "./kubeconfig"
}
