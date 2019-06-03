terraform {
  required_version = ">= 0.11.8"
}

provider "random" {
  version = "= 1.3.1"
}

resource "random_string" "suffix" {
  length  = 8
  special = false
}

locals {
  cluster_name = "astronomer-${var.customer_id}-${var.environment}-${random_string.suffix.result}"

  postgres_airflow_password = "${ var.postgres_airflow_password == "" ? random_string.postgres_airflow_password.result : var.postgres_airflow_password }"

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
      asg_desired_capacity          = "2"
      asg_min_size                  = "2"
      asg_max_size                  = "${var.max_cluster_size}"
    },
  ]

  tags = {
    Environment = "${var.environment}"
    Owner       = "${var.owner}"
  }
}
