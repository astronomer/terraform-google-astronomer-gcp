/*
This lambda is used to dynamically
find the name of the ELB, since an
appropriate terraform data source
does not exist (look up ELB by vpc / tags)
*/

# This data source will be used in other files
data "aws_elb" "nginx_elb" {
  name = "${data.aws_lambda_invocation.elb_name.result_map["Name"]}"
}

data "aws_lambda_invocation" "elb_name" {
  depends_on = ["aws_lambda_function.elb_lookup",
    "aws_iam_role_policy.elb_lookup_policy",
    "null_resource.astronomer_deploy",
  ]

  function_name = "${aws_lambda_function.elb_lookup.function_name}"

  input = "{}"
}

resource "aws_iam_role_policy" "elb_lookup_policy" {
  name = "${var.customer_id}_elb_lookup_policy"
  role = "${aws_iam_role.elb_lookup_role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "elasticloadbalancing:DescribeLoadBalancers",
        "elasticloadbalancing:DescribeTags",
        "elasticloadbalancing:SetLoadBalancerListenerSSLCertificate"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role" "elb_lookup_role" {
  name = "${var.customer_id}_elb_lookup_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

data "archive_file" "elb_lookup" {
  type        = "zip"
  source_file = "./files/elb_lookup.py"
  output_path = "./elb_lookup.py.zip"
}

resource "aws_lambda_function" "elb_lookup" {
  depends_on       = ["data.archive_file.elb_lookup"]
  filename         = "elb_lookup.py.zip"
  function_name    = "${var.customer_id}_elb_lookup_function"
  role             = "${aws_iam_role.elb_lookup_role.arn}"
  handler          = "elb_lookup.my_handler"
  source_code_hash = "${data.archive_file.elb_lookup.output_base64sha256}"
  runtime          = "python3.7"

  environment {
    variables = {
      VPC_ID       = "${module.vpc.vpc_id}"
      CLUSTER_NAME = "${local.cluster_name}"
    }
  }
}
