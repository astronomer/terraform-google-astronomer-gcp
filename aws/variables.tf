#
# Variables Configuration
#
variable "cluster_type" {
  default = "private"
  type    = "string"
}

# this is the basename that will be used
# for naming other things
variable "customer_id" {
  description = "this lowercase, letters-only string will be used to label/prefix/customer_id some of your AWS resources. In the case of a peered private-cloud deployment, please provide a string indicating the customer name. This will be used to create a subdomain and will be frequently visible to customers and often typed by the users."
  type        = "string"
}

variable "cluster_version" {
  default = "1.12"
  type    = "string"
}

variable "postgres_airflow_password" {
  default     = ""
  description = "The password for the 'airflow' user in postgres. If blank, will be auto-generated"
  type        = "string"
}

variable "owner" {
  default     = "astronomer"
  description = "In your organization, who is responsible for this infrastructure? Please use lowercase, letters only."
  type        = "string"
}

variable "environment" {
  default     = "prod"
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

variable "db_instance_type" {
  default = "db.r4.large"
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

variable "admin_email" {
  default     = "steven@astronomer.io"
  description = "An email address that will be used to create the let's encrypt cert"
  type        = "string"
}

variable "route53_domain" {
  default     = "airflow.run"
  description = "The route53 domain in your account you want to use for the *.<customer_id>.route53_domain subdomain"
  type        = "string"
}

variable "management_api" {
  default = "public"
  type    = "string"
}

variable "bastion_terraform_version" {
  default = "0.11.13"
  type    = "string"
}

variable "acme_server" {
  # default = "https://acme-staging-v02.api.letsencrypt.org/directory"
  default = "https://acme-v02.api.letsencrypt.org/directory"
  type    = "string"
}

variable "peer_account_id" {
  description = "The account ID to pair with"
  type        = "string"
}

variable "peer_vpc_id" {
  description = "The VPC ID to pair with, if this is an empty string, then we will not peer with any VPC"
  type        = "string"
}

variable "ten_dot_what_cidr" {
  description = "10.X.0.0/16 - choose X"

  # This is probably not that common
  default = "234"
  type    = "string"
}
