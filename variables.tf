variable "deployment_id" {
  description = "A short, lowercase-letters-only identifier for this deployment"
}

variable "dns_managed_zone" {
  description = "The name of the google dns managed zone we should use"
}

variable "machine_type" {
  default     = "n1-standard-4"
  description = "The GCP machine type for GKE worker nodes"
}

variable "machine_type_bastion" {
  default     = "g1-small"
  description = "The GCP machine type for the bastion"
}

variable "max_node_count" {
  default     = 10
  description = "The approximate maximum number of nodes in the GKE worker node pool. The exact max will be 3 * ceil(your_value / 3.0) ."
}

variable "min_master_version" {
  default     = ""
  description = "The minimum version of the master. Default is the latest available from the API."
}

variable "node_version" {
  default     = ""
  description = "The version of Kubernetes in GKE cluster. Default is the latest available from the API."
}

variable "gke_secondary_ip_ranges_pods" {
  default     = "10.32.0.0/14"
  description = "GKE Secondary IP Ranges for Pods"
}

variable "gke_secondary_ip_ranges_services" {
  default     = "10.98.0.0/20"
  description = "GKE Secondary IP Ranges for Services"
}

variable "iap_cidr_ranges" {
  type        = list(string)
  description = "Cloud IAP CIDR Range as described on https://cloud.google.com/iap/docs/using-tcp-forwarding"

  default = [
    "35.235.240.0/20",
  ]
}

variable "email" {
  type        = string
  description = "An email address to use for Let's Encrypt"
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
  type        = map(string)
  description = "The Name & Project of the Image Family with which Bastion will be created."

  default = {
    name    = "ubuntu-1804-lts"
    project = "ubuntu-os-cloud"
  }
}

