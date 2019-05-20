output "base_domain" {
  value = "astro.${var.route53_domain}"
}

output "bastion_ssh_command" {
  value = "ssh ubuntu@${aws_instance.bastion.public_ip}"
}
