#
# Variables Configuration
#

variable "cluster_type" {
  default = "private"
  type    = "string"
}

# this is the basename that will be used
# for naming other things
variable "base_name" {
  type = "string"
}

variable "cluster_version" {
  default = "1.12"
  type    = "string"
}

variable "owner" {
  type = "string"
}

variable "environment" {
  default = "dev"
  type    = "string"
}

variable "aws_region" {
  default = "us-east-1"
  type    = "string"
}

variable "lb_instance_type" {
  default = "t2.small"

  # default = "m5.xlarge"
  type = "string"
}

variable "worker_instance_type" {
  # default = "t2.small"
  default = "m5.xlarge"
  type    = "string"
}

# variable "other_instance_types" {
#   default = "t2.micro,t3.small,t3.micro"
#   type    = "string"
# }

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

variable "map_roles" {
  default = []
  type    = "list"
}

# this is odd but necessary
# should correspond to the above
variable "map_roles_count" {
  default = 0
  type    = "string"
}

# TODO: determine minimal required permissions to deploy
variable "map_users" {
  description = "Additional IAM users to add to the aws-auth configmap."
  type        = "list"

  default = [
    {
      user_arn = "arn:aws:iam::668666347261:root"
      username = "steven"
      group    = "system:masters"
    },
  ]
}

# this is odd but necessary
# should correspond to the above
variable "map_users_count" {
  default = 1
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
  type = "string"
}

variable "route53_domain" {
  type = "string"
}

variable "management_api" {
  default = "public"
  type    = "string"
}
