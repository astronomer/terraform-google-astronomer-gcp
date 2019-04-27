output "bastion_ip" {
  value = "${google_compute_instance.bastion.network_interface.0.network_ip}"
}
