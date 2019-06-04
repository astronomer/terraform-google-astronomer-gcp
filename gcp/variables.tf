variable deployment_id {
  description = "A short, lowercase-letters-only identifier for this deployment"
}

variable "bastion_terraform_version" {
  default = "0.11.13"
  type    = "string"
}

variable "enable_istio" {
  default = "true"
  type    = "string"
}

variable "acme_server" {
  # default = "https://acme-staging-v02.api.letsencrypt.org/directory"
  default = "https://acme-v02.api.letsencrypt.org/directory"
  type    = "string"
}

variable google_domain {
  description = "A domain you own in this google account that you want to use for the deployment"
}

variable region {
  default     = "us-east4"
  description = "The GCP region to deploy infrastructure into"
}

variable zone {
  default     = "us-east4-a"
  description = "The GCP zone to deploy infrastructure into"
}

variable project {
  description = "The Google Cloud project name to use"
}

variable machine_type {
  default     = "n1-standard-4"
  description = "The GCP machine type for GKE worker nodes"
}

variable machine_type_bastion {
  default     = "g1-small"
  description = "The GCP machine type for the bastion"
}

variable max_node_count {
  default     = 10
  description = "The approximate maximum number of nodes in the GKE worker node pool. The exact max will be 3 * ceil(your_value / 3.0) ."
}

variable "min_master_version" {
  default     = "1.12.7-gke.10"
  description = "The minimum version of the master."
}

variable node_version {
  default     = "1.12.7-gke.10"
  description = "The version of Kubernetes in GKE cluster"
}

variable "gke_secondary_ip_ranges_pods" {
  description = "GKE Secondary IP Ranges for Pods"
}

variable "gke_secondary_ip_ranges_services" {
  description = "GKE Secondary IP Ranges for Services"
}

variable "iap_cidr_ranges" {
  type        = "list"
  description = "Cloud IAP CIDR Range as described on https://cloud.google.com/iap/docs/using-tcp-forwarding"

  default = [
    "35.235.240.0/20",
  ]
}

variable "bastion_user_emails" {
  type        = "list"
  description = "List of email addresses of users who be able to SSH into Bastion using Cloud IAP & OS Login"
}

variable "bastion_admin_emails" {
  type        = "list"
  description = "List of email addresses of users with Sudo who be able to SSH into Bastion using Cloud IAP & OS Login"
}

variable "postgres_airflow_password" {
  description = "Password for the 'airflow' user in Cloud SQL Postgres Instance. If not specified, creates a random Password."
  default     = ""
}

variable "cloud_sql_tier" {
  default     = "db-f1-micro"
  description = "The machine tier (First Generation) or type (Second Generation) to use. See https://cloud.google.com/sql/pricing for supported tiers."
}

variable "cloud_sql_availability_type" {
  default     = "REGIONAL"
  description = "Whether a PostgreSQL instance should be set up for high availability (REGIONAL) or single zone (ZONAL)."
}

variable "bastion_image_family" {
  type        = "map"
  description = "The Name & Project of the Image Family with which Bastion will be created."

  default = {
    name    = "ubuntu-1804-lts"
    project = "ubuntu-os-cloud"
  }
}

variable "astronomer_namespace" {
  default = "astronomer"
}
