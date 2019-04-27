variable region {
  default     = "us-east4"
  description = "The GCP region to deploy infrastructure into"
}

variable zone {
  default     = "us-east4-a"
  description = "The GCP zone to deploy infrastructure into"
}

variable project {
  description = "The GCP project to deploy infrastructure into"
}

variable cluster_name {
  description = "The name of the GKE cluster"
}

variable machine_type {
  default     = "n1-standard-8"
  description = "The GCP machine type for GKE worker nodes"
}

variable min_node_count {
  default     = 3
  description = "The minimum amount of worker nodes in GKE cluster"
}

variable max_node_count {
  default     = 10
  description = "The maximum amount of worker nodes in GKE cluster"
}

variable node_version {
  default     = "1.12.7-gke.7"
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

variable "bastion_users" {
  type        = "list"
  description = "List of email addresses of users who be able to SSH into Bastion using Cloud IAP & OS Login"
}

variable "bastion_admins" {
  type        = "list"
  description = "List of email addresses of users with Sudo who be able to SSH into Bastion using Cloud IAP & OS Login"
}
