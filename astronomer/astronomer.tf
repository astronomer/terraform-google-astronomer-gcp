# Initialize kubectl
provider "kubernetes" {
  config_path      = "./kubeconfig"
  load_config_file = true
}

resource "kubernetes_namespace" "astronomer" {
  metadata {
    name = "astronomer"
  }
}

# Create prerequisite resources

resource "kubernetes_service_account" "tiller" {
  metadata {
    name      = "tiller"
    namespace = "kube-system"
  }
}

resource "kubernetes_cluster_role_binding" "tiller_binding" {
  depends_on = ["kubernetes_service_account.tiller"]

  metadata {
    name = "tiller-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "tiller"
    namespace = "kube-system"
  }
}

resource "kubernetes_role" "tiller_role" {
  depends_on = ["kubernetes_service_account.tiller",
    "kubernetes_namespace.astronomer",
  ]

  metadata {
    name      = "tiller-manager"
    namespace = "astronomer"
  }

  rule {
    api_groups = ["", "batch", "extensions", "apps"]
    resources  = ["*"]
    verbs      = ["*"]
  }
}

# Initialize helm
provider "helm" {
  service_account = "tiller"
  debug           = true

  kubernetes {
    config_path = "./kubeconfig"
  }
}

data "kubernetes_secret" "astro_db_postgresql" {
  depends_on = ["helm_release.astro_db",
    "kubernetes_namespace.astronomer",
  ]

  metadata {
    name      = "astro-db-postgresql"
    namespace = "astronomer"
  }
}

resource "kubernetes_secret" "astronomer_bootstrap" {
  depends_on = ["helm_release.astro_db",
    "kubernetes_namespace.astronomer",
  ]

  metadata {
    name      = "astronomer-bootstrap"
    namespace = "astronomer"
  }

  type = "kubernetes.io/generic"

  data {
    "connection" = "postgres://postgres:${lookup(data.kubernetes_secret.astro_db_postgresql.data,"postgresql-password")}@astro-db-postgresql.astronomer.svc.cluster.local:5432"
  }
}

# TODO
# Cloning the repository from github, is not the best way
# to do this. We should use helm repository directly

resource "null_resource" "helm_repo" {
  provisioner "local-exec" {
    command = "if ! [ -d ./helm.astronomer.io ]; then git clone ${var.git_clone_from}; fi"
  }
}

resource "null_resource" "checkout_astronomer_version" {
  depends_on = ["null_resource.helm_repo"]

  provisioner "local-exec" {
    command = "cd ./helm.astronomer.io && git checkout ${var.astronomer_version} && cd .."
  }
}

resource "helm_release" "astronomer" {
  depends_on = ["kubernetes_secret.astronomer_bootstrap",
    "null_resource.checkout_astronomer_version",
    "kubernetes_namespace.astronomer",
  ]

  name      = "astronomer"
  chart     = "./helm.astronomer.io"
  namespace = "astronomer"
  wait      = true

  values = [<<EOF
---
global:
  baseDomain: ${var.base_domain}
  tlsSecret: astronomer-tls
nginx:
  loadBalancerIP: ~
  privateLoadBalancer: ${var.cluster_type == "private" ? true: false}
EOF
  ]
}

resource "helm_release" "astro_db" {
  depends_on = ["kubernetes_service_account.tiller",
    "kubernetes_namespace.astronomer",
  ]

  wait      = true
  name      = "astro-db"
  chart     = "stable/postgresql"
  namespace = "astronomer"
}

resource "kubernetes_secret" "astronomer_tls" {
  depends_on = ["kubernetes_namespace.astronomer"]

  metadata {
    name      = "astronomer-tls"
    namespace = "astronomer"
  }

  type = "kubernetes.io/tls"

  data {
    "tls.crt" = "${file("/opt/astronomer_certs/tls.crt")}"
    "tls.key" = "${file("/opt/astronomer_certs/tls.key")}"
  }
}
