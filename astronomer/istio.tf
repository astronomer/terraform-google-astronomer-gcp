resource "kubernetes_namespace" "istio_system" {
  metadata {
    name = "istio-system"
  }
}

data "helm_repository" "istio_repo" {
  name = "istio.io"
  url  = "https://storage.googleapis.com/istio-release/releases/${var.istio_helm_release_version}/charts/"
}

resource "helm_release" "istio_init" {
  count      = "${var.enable_istio == "true" ? 1 : 0}"
  name       = "istio-init"
  repository = "${data.helm_repository.istio_repo.name}"
  chart      = "istio-init"
  namespace  = "${kubernetes_namespace.istio_system.metadata.0.name}"
}

resource "helm_release" "istio" {
  count      = "${var.enable_istio == "true" ? 1 : 0}"
  depends_on = ["helm_release.istio_init"]
  name       = "istio"
  repository = "${data.helm_repository.istio_repo.name}"
  chart      = "istio"
  namespace  = "${kubernetes_namespace.istio_system.metadata.0.name}"
  wait       = true

  set {
    name  = "kiali.enabled"
    value = "true"
  }
}
