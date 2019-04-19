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
  default     = "1.11.7-gke.12"
  description = "The version of Kubernetes in GKE cluster"
}
