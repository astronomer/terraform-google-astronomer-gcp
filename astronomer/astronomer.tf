# Initialize kubectl

resource "kubernetes_namespace" "astronomer" {
  metadata {
    name = "${var.astronomer_namespace}"
  }
}

# Create prerequisite resources

resource "kubernetes_secret" "astronomer_bootstrap" {
  depends_on = ["kubernetes_namespace.astronomer"]

  metadata {
    name      = "astronomer-bootstrap"
    namespace = "${var.astronomer_namespace}"
  }

  type = "kubernetes.io/generic"

  data {
    "connection" = "${file("/opt/db_password/connection_string")}"
  }
}

resource "kubernetes_secret" "astronomer_tls" {
  depends_on = ["kubernetes_namespace.astronomer"]

  metadata {
    name      = "astronomer-tls"
    namespace = "${var.astronomer_namespace}"
  }

  type = "kubernetes.io/tls"

  data {
    "tls.crt" = "${file("/opt/tls_secrets/tls.crt")}"
    "tls.key" = "${file("/opt/tls_secrets/tls.key")}"
  }
}

# TODO
# Cloning the repository from github, is not the best way
# to do this. We should use helm repository directly

resource "null_resource" "helm_repo" {
  provisioner "local-exec" {
    command = <<EOF
    if ! [ -d ${path.module}/helm.astronomer.io ];
    then git clone ${var.git_clone_from};
    fi
    cd ${path.module}/helm.astronomer.io && \
    git checkout ${var.astronomer_version}
    EOF
  }

  provisioner "local-exec" {
    when    = "destroy"
    command = "rm -rf ${path.module}/helm.astronomer.io"
  }
}

resource "helm_release" "astronomer" {
  depends_on = ["kubernetes_secret.astronomer_bootstrap",
    "null_resource.helm_repo",
    "kubernetes_namespace.astronomer",
  ]

  name      = "astronomer"
  chart     = "./helm.astronomer.io"
  namespace = "${var.astronomer_namespace}"
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
