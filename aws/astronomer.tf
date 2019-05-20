module "astronomer" {
  source        = "../astronomer"
  namespace_uid = "${kubernetes_namespace.astronomer.uid}"
}
