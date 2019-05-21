#
# Variables Configuration
#

variable "cluster_type" {
  default = "private"
  type    = "string"
}

# this is the basename that will be used
# for naming other things
variable "label" {
  description = "this lowercase, letters-only string will be used to label/prefix some of your AWS resources"
  type        = "string"
}

variable "cluster_version" {
  default = "1.12"
  type    = "string"
}

variable "owner" {
  description = "In your organization, who is responsible for this infrastructure? Please use lowercase, letters only."
  type        = "string"
}

variable "environment" {
  description = "Choose 'dev', 'qa', or 'prod'"
  type        = "string"
}

variable "aws_region" {
  default = "us-east-1"
  type    = "string"
}

variable "lb_instance_type" {
  default = "t2.small"
  type    = "string"
}

variable "worker_instance_type" {
  default = "m5.xlarge"
  type    = "string"
}

variable "max_cluster_size" {
  default = "8"
  type    = "string"
}

variable "min_cluster_size" {
  default = "4"
  type    = "string"
}

variable "percent_on_demand" {
  default = "0"
  type    = "string"
}

variable "map_accounts" {
  default = []
  type    = "list"
}

# this is odd but necessary
# should correspond to the above
variable "map_accounts_count" {
  default = 0
  type    = "string"
}

variable "acme_server" {
  default = "https://acme-staging-v02.api.letsencrypt.org/directory"
  type    = "string"
}

variable "admin_email" {
  description = "An email address"
  type        = "string"
}

variable "route53_domain" {
  description = "The route53 domain in your account you want to use for the *.astro.route53_domain subdomain"
  type        = "string"
}

variable "management_api" {
  default = "private"
  type    = "string"
}

variable "bastion_terraform_version" {
  default = "0.11.13"
  type    = "string"
}
