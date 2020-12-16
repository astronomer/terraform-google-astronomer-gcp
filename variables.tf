variable "deployment_id" {
  description = "A short, lowercase-letters-only identifier for this deployment"
}

variable "dns_managed_zone" {
  default     = ""
  type        = string
  description = "The name of the google dns managed zone we should use"
}

variable "kube_version_gke" {
  default     = "1.14"
  description = "The kubernetes version to use in GKE"
}

variable "gke_release_channel" {
  default     = "REGULAR"
  type        = string
  description = "The GKE Release channel to use. Blank for none"
}

variable "machine_type_bastion" {
  default     = "g1-small"
  description = "The GCP machine type for the bastion"
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

variable "do_not_create_a_record" {
  type    = bool
  default = false
}

variable "lets_encrypt" {
  type    = bool
  default = true
}

variable "webhook_ports" {
  type        = list(string)
  default     = []
  description = "When custom API services are added to the cluster, the corresponding ports must be opened on the network's firewall, allowing GKE's control plane to access the api service backend running in the node pool. The ports should be provided as a list of strings."
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


### Node Pool settings
# Blue / Green node pools feature is to allow Terraform users
# careful control of node pool changes


## Platform node pool: Blue

variable "enable_blue_platform_node_pool" {
  type        = bool
  default     = true
  description = "Turn on the blue platform node pool"
}

variable "blue_platform_np_initial_node_count" {
  type        = number
  default     = 1
  description = "Initial node count for the blue platform node pool"
}

variable "machine_type_platform_blue" {
  default     = "n1-standard-4"
  type        = string
  description = "The GCP machine type for GKE worker nodes running platform components"
}

variable "disk_size_platform_blue" {
  default     = 100
  type        = number
  description = "Number of GB available on Nodes' local disks for the platform node pool, which runs Astronomer components"
}

variable "max_node_count_platform_blue" {
  default     = 10
  type        = number
  description = "The approximate maximum number of nodes in the platform node pool. The exact max will be 3 * ceil(your_value / 3.0) in the case of regional cluster, and exactly as configured in the case of zonal cluster."
}

variable "platform_node_pool_taints_blue" {
  description = "Taints to apply to the platform node pool "
  type        = list(any)
  default     = []
}

## Platform node pool: Green

variable "enable_green_platform_node_pool" {
  type        = bool
  default     = false
  description = "Turn on the green platform node pool"
}

variable "green_platform_np_initial_node_count" {
  type        = number
  default     = 1
  description = "Initial node count for the green platform node pool"
}

variable "machine_type_platform_green" {
  default     = "n1-standard-4"
  type        = string
  description = "The GCP machine type for GKE worker nodes running platform components"
}

variable "disk_size_platform_green" {
  default     = 100
  type        = number
  description = "Number of GB available on Nodes' local disks for the platform node pool, which runs Astronomer components"
}

variable "max_node_count_platform_green" {
  default     = 10
  type        = number
  description = "The approximate maximum number of nodes in the platfor node pool. The exact max will be 3 * ceil(your_value / 3.0) in the case of regional cluster, and exactly as configured in the case of zonal cluster."
}

variable "platform_node_pool_taints_green" {
  description = "Taints to apply to the Platform Node Pool "
  type        = list(any)
  default     = []
}


## Multi-tenant node pool: Blue

variable "enable_blue_mt_node_pool" {
  type        = bool
  default     = true
  description = "Turn on the blue multi-tenant node pool"
}

variable "blue_mt_np_initial_node_count" {
  type        = number
  default     = 1
  description = "Initial node count for the blue multi-tenant node pool"
}

variable "machine_type_multi_tenant_blue" {
  default     = "n1-standard-4"
  description = "The GCP machine type for GKE worker nodes running multi-tenant workloads"
}

variable "disk_size_multi_tenant_blue" {
  default     = 100
  type        = number
  description = "Number of GB available on Nodes' local disks for the multi-tenant node pool, which runs Airflow deployments"
}

variable "max_node_count_multi_tenant_blue" {
  default     = 10
  description = "The approximate maximum number of nodes in the GKE multi-tenant node pool. The exact max will be 3 * ceil(your_value / 3.0) in the case of regional cluster, and exactly as configured in the case of zonal cluster."
}

variable "mt_node_pool_taints_blue" {
  description = "Taints to apply to the Multi-Tenant Node Pool "
  type        = list(string)
  default     = []
}

variable "enable_gvisor_blue" {
  type        = bool
  default     = false
  description = "Should this module configure the multi-tenant node pool for the gvisor runtime?"
}

## Multi-tenant node pool: Green

variable "enable_green_mt_node_pool" {
  type        = bool
  default     = false
  description = "Turn on the green multi-tenant node pool"
}

variable "green_mt_np_initial_node_count" {
  type        = number
  default     = 1
  description = "Initial node count for the green multi-tenant node pool"
}

variable "machine_type_multi_tenant_green" {
  default     = "n1-standard-4"
  description = "The GCP machine type for GKE worker nodes running multi-tenant workloads"
}

variable "disk_size_multi_tenant_green" {
  default     = 100
  type        = number
  description = "Number of GB available on Nodes' local disks for the multi-tenant node pool, which runs Airflow components"
}

variable "max_node_count_multi_tenant_green" {
  default     = 10
  description = "The approximate maximum number of nodes in the GKE multi-tenant node pool. The exact max will be 3 * ceil(your_value / 3.0) in the case of regional cluster, and exactly as configured in the case of zonal cluster."
}

variable "mt_node_pool_taints_green" {
  description = "Taints to apply to the Multi-Tenant Node Pool"
  type        = list(string)
  default     = []
}

variable "enable_gvisor_green" {
  type        = bool
  default     = false
  description = "Should this module configure the multi-tenant node pool for the gvisor runtime?"
}

## Dynamic node pool (legacy pre-blue-green pool)

variable "create_dynamic_pods_nodepool" {
  type        = bool
  default     = false
  description = "If true, creates a NodePool for the pods spun up using KubernetesPodsOperator or KubernetesExecutor"
}

variable "dynamic_np_initial_node_count" {
  type        = number
  default     = 1
  description = "Initial node count for the dynamic node pool"
}

variable "disk_size_dynamic" {
  default     = 100
  type        = number
  description = "Number of GB available on Nodes' local disks for the dynamic node pool, which runs Airflow deployments' ephemeral pods such as KubeExecutor pods and Kubernetes Pod Operator pods"
}

variable "dynamic_node_pool_taints" {
  description = "Taints to apply to the dynamic node pool "
  type        = list(string)
  default     = []
}

variable "max_node_count_dynamic" {
  default     = 10
  description = "The approximate maximum number of nodes in the GKE dynamic node pool. The exact max will be 3 * ceil(your_value / 3.0) for a regional cluster, or exactly as configured for zonal cluster."
}

variable "enable_gvisor_dynamic" {
  type        = bool
  default     = false
  description = "Should this module configure the dynamic node pool for the gvisor runtime?"
}

variable "machine_type_dynamic" {
  default     = "n1-standard-4"
  description = "The GCP machine type for the bastion"
}

## Dynamic node pool blue (added 2020-12-16)

variable "enable_dynamic_blue_node_pool" {
  type        = bool
  default     = false
  description = "Turn on the blue dynamic node pool"
}

variable "dynamic_blue_np_initial_node_count" {
  type        = number
  default     = 1
  description = "Initial node count for the blue dynamic node pool"
}

variable "machine_type_dynamic_blue" {
  default     = "n1-standard-16"
  description = "The GCP machine type for the blue dynamic node pool"
}

variable "disk_size_dynamic_blue" {
  default     = 100
  type        = number
  description = "Number of GB available on Nodes' local disks for the blue dynamic node pool"
}

variable "max_node_count_dynamic_blue" {
  default     = 10
  description = "The approximate maximum number of nodes in the blue dynamic node pool. The exact max will be 3 * ceil(your_value / 3.0) in the case of regional cluster, and exactly as configured in the case of zonal cluster."
}

variable "dynamic_blue_node_pool_taints" {
  description = "Taints to apply to the blue dynamic node pool"
  type        = list(string)
  default     = []
}

variable "enable_gvisor_dynamic_blue" {
  type        = bool
  default     = false
  description = "Should gvisor be enabled for the blue dynamic node pool?"
}

## Dynamic node pool green (added 2020-12-16)

variable "enable_dynamic_green_node_pool" {
  type        = bool
  default     = false
  description = "Turn on the green dynamic node pool"
}

variable "dynamic_green_np_initial_node_count" {
  type        = number
  default     = 1
  description = "Initial node count for the green dynamic node pool"
}

variable "machine_type_dynamic_green" {
  default     = "n1-standard-16"
  description = "The GCP machine type for the green dynamic node pool"
}

variable "disk_size_dynamic_green" {
  default     = 100
  type        = number
  description = "Number of GB available on Nodes' local disks for the green dynamic node pool"
}

variable "max_node_count_dynamic_green" {
  default     = 10
  description = "The approximate maximum number of nodes in the green dynamic node pool. The exact max will be 3 * ceil(your_value / 3.0) in the case of regional cluster, and exactly as configured in the case of zonal cluster."
}

variable "dynamic_green_node_pool_taints" {
  description = "Taints to apply to the green dynamic node pool"
  type        = list(string)
  default     = []
}

variable "enable_gvisor_dynamic_green" {
  type        = bool
  default     = false
  description = "Should gvisor be enabled for the green dynamic node pool?"
}


## Extra stuff

variable "kube_api_whitelist_cidr" {
  default     = ""
  type        = string
  description = "If not provided, will whitelist only the calling IP, otherwise provide this CIDR block. This is ignore if var.management_endpoint is not set to 'public'"
}

variable "pod_security_policy_enabled" {
  default     = false
  type        = bool
  description = "Turn on pod security policies in the cluster"
}

variable "enable_spotinist" {
  default     = false
  type        = bool
  description = "Run the nodes using Spotinist"
}
