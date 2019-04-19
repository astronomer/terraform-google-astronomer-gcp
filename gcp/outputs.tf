output "bastion_ip" {
  value = "${google_compute_instance.bastion.network_interface.0.access_config.0.nat_ip}"
}

output "key" {
  value = "${base64decode(google_service_account_key.mykey.private_key)}"
}
