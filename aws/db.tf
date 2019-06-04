resource "random_id" "db_name_suffix" {
  byte_length = 4
}

resource "random_string" "postgres_airflow_password" {
  count   = "${ var.postgres_airflow_password == "" ? 1 : 0 }"
  length  = 32
  special = false
}

module "aurora" {
  source                          = "terraform-aws-modules/rds-aurora/aws"
  name                            = "${var.customer_id}astrodb"
  engine                          = "aurora-postgresql"
  engine_version                  = "10.6"
  subnets                         = ["${module.vpc.database_subnets}"]
  vpc_id                          = "${module.vpc.vpc_id}"
  replica_count                   = 1
  instance_type                   = "${var.db_instance_type}"
  apply_immediately               = true
  skip_final_snapshot             = "${ var.environment == "dev" ? true : false }"
  db_parameter_group_name         = "${aws_db_parameter_group.aurora_db_postgres_parameter_group.id}"
  db_cluster_parameter_group_name = "${aws_rds_cluster_parameter_group.aurora_cluster_postgres_parameter_group.id}"

  # NOTE: This is only supported by Aurora for MySQL
  # enabled_cloudwatch_logs_exports = ["audit", "error", "general", "slowquery"]
  enabled_cloudwatch_logs_exports = []

  username            = "airflow"
  password            = "${local.postgres_airflow_password}"
  publicly_accessible = false
}

resource "aws_db_parameter_group" "aurora_db_postgres_parameter_group" {
  name        = "${var.customer_id}-aurora-db-postgres-parameter-group"
  family      = "aurora-postgresql10"
  description = "${var.customer_id}-aurora-db-postgres-parameter-group"
}

resource "aws_rds_cluster_parameter_group" "aurora_cluster_postgres_parameter_group" {
  name        = "${var.customer_id}-aurora-postgres-cluster-parameter-group"
  family      = "aurora-postgresql10"
  description = "${var.customer_id}-aurora-postgres-cluster-parameter-group"
}

# this permission is used to validate the connection
resource "aws_security_group_rule" "allow_access_from_bastion" {
  type                     = "ingress"
  from_port                = "${module.aurora.this_rds_cluster_port}"
  to_port                  = "${module.aurora.this_rds_cluster_port}"
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.bastion_sg.id}"
  security_group_id        = "${module.aurora.this_security_group_id}"
}

resource "aws_security_group_rule" "allow_access_from_eks_workers" {
  type                     = "ingress"
  from_port                = "${module.aurora.this_rds_cluster_port}"
  to_port                  = "${module.aurora.this_rds_cluster_port}"
  protocol                 = "tcp"
  source_security_group_id = "${module.eks.worker_security_group_id}"
  security_group_id        = "${module.aurora.this_security_group_id}"
}
