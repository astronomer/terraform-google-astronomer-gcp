resource "aws_iam_role" "kube_admin" {
  name = "astronomer_kube_admin_role_${var.customer_id}"

  # This allows EC2 to assign this as an instance profile
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = "${local.tags}"
}

resource "aws_iam_instance_profile" "bastion_instance_profile" {
  name = "astronomer_bastion_kube_admin_${var.customer_id}_${var.environment}"
  role = "${aws_iam_role.kube_admin.name}"
}
