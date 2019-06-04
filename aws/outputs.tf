output "base_domain" {
  value = "astro.${var.route53_domain}"
}

output "bastion_ssh_command" {
  value = "ssh ubuntu@${aws_instance.bastion.public_ip}"
}

output "test_bastion_host_command" {
  value = "py.test --host='ssh://ubuntu@${aws_instance.bastion.public_ip}:22' ../test_bastion.py"
}
