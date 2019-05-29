/*
resource "aws_vpc_peering_connection" "peer" {
  vpc_id        = "${module.vpc.vpc_id}"
  peer_vpc_id   = "${var.peer_vpc_id}"
  peer_owner_id = "${var.peer_account_id}"
  auto_accept   = true
  tags = {
    Side = "Requester"
  }
}
*/

