variable "deployment_id" {
  description = "A short, lowercase-letters-only identifier for this deployment"
}

variable "dns_managed_zone" {
  default     = ""
  type        = string
  description = "The name of the google dns managed zone we should use"
}

variable "disk_size_multi_tenant" {
  default     = 100
  type        = number
  description = "Number of GB available on Nodes' local disks for the multi-tenant node pool, which runs Airflow deployments"
}

variable "disk_size_platform" {
  default     = 100
  type        = number
  description = "Number of GB available on Nodes' local disks for the platform node pool, which runs Astronomer components"
}

variable "disk_size_dynamic" {
  default     = 100
  type        = number
  description = "Number of GB available on Nodes' local disks for the dynamic, multi-tenant node pool, which runs Airflow deployments' ephemeral pods such as KubeExecutor pods and Kubernetes Pod Operator pods"
}

variable "kube_version_gke" {
  default     = "1.14"
  description = "The kubernetes version to use in GKE"
}

variable "machine_type" {
  default     = "n1-standard-4"
  description = "The GCP machine type for GKE worker nodes running multi-tenant workloads"
}

variable "machine_type_platform" {
  default     = "n1-standard-4"
  description = "The GCP machine type for GKE worker nodes running platform components"
}

variable "green_machine_type_platform" {
  default     = "n1-standard-4"
  description = "The GCP machine type for GKE worker nodes running platform components"
}

variable "machine_type_bastion" {
  default     = "g1-small"
  description = "The GCP machine type for the bastion"
}

variable "max_node_count" {
  default     = 10
  description = "The approximate maximum number of nodes in the GKE worker node pool. The exact max will be 3 * ceil(your_value / 3.0) ."
}

/*
variable "min_master_version" {
  default     = ""
  description = "The minimum version of the master. Default is the latest available from the API."
}

variable "node_version" {
  default     = ""
  description = "The version of Kubernetes in GKE cluster. Default is the latest available from the API."
}
*/

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

variable "zonal_cluster" {
  default     = false
  type        = bool
  description = "A zonal cluster is less reliable than a regional cluster, but it is less expensive. The default is false which makes it a regional cluster."
}

variable "management_endpoint" {
  default = "private"
}

variable "wait_for" {
  type        = string
  default     = "600"
  description = "How long to wait after GKE cluster is up in order for the cluster to stabilize"
}

variable "enable_gvisor" {
  type        = bool
  default     = false
  description = "Should this module configure the multi-tenant node pool for the gvisor runtime?"
}

variable "do_not_create_a_record" {
  type    = bool
  default = false
}

variable "lets_encrypt" {
  type    = bool
  default = true
}

variable "mt_node_pool_taints" {
  description = "Taints to apply to the Multi-Tenant Node Pool "
  type        = "list"
  default     = []
}

variable "platform_node_pool_taints" {
  description = "Taints to apply to the Platform Node Pool "
  type        = "list"
  default     = []
}

variable "dp_node_pool_taints" {
  description = "Taints to apply to the Dynamic-Pods Node Pool "
  type        = "list"
  default     = []
}

variable "webhook_ports" {
  type        = list(string)
  default     = []
  description = "When custom API services are added to the cluster, the corresponding ports must be opened on the network's firewall, allowing GKE's control plane to access the api service backend running in the node pool. The ports should be provided as a list of strings."
}

variable "create_dynamic_pods_nodepool" {
  type        = bool
  default     = false
  description = "If true, creates a NodePool for the pods spun up using KubernetesPodsOperator or KubernetesExecutor"
}

variable "enable_gke_metered_billing" {
  type        = bool
  default     = false
  description = "If true, enables GKE metered billing to track costs on namespaces & label level"
}

variable "deploy_db" {
  type        = bool
  default     = true
  description = "Do you want a database deployed in this project?"
}

variable "db_max_connections" {
  type        = number
  default     = 0
  description = "Configure the max connections to the database. If omitted, it will not be configured (default of zero indicates do not specify)."
}

variable "enable_green_platform_node_pool" {
  type        = bool
  default     = false
  description = "Turn on the green platform node pool"
}
