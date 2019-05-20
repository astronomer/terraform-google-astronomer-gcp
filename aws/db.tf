# This kind of DB is OK for POC, but we should write an RDS
# resource for production

resource "helm_release" "astro-db" {

    depends_on = ["kubernetes_service_account.tiller",
                  "kubernetes_namespace.astronomer"]

    wait = true
    name = "astro-db"
    chart = "stable/postgresql"
    namespace = "astronomer"
}
