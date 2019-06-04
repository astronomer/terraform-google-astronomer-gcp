resource "null_resource" "peer_with_customer" {
  count = "${var.peer_vpc_id == "" ? 0 : 1}"

  # this makes this resource run each time
  triggers {
    build_number = "${timestamp()}"
  }

  provisioner "local-exec" {
    working_dir = "${path.module}"

    command = "python3 files/peer_vpc.py ${var.peer_account_id} ${var.peer_vpc_id} ${var.aws_region} ${module.vpc.vpc_id} ${join(" ", module.vpc.private_subnets)} >> peering.log"
  }
}
