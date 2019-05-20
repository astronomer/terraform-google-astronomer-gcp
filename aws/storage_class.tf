# I think that this is created by default on EKS
# but I'm leaving this here for now, will delete soon
# if we confirm it's not needed.
/*
resource "kubernetes_storage_class" "postgres_storage_class" {
  depends_on = ["module.eks"]
  metadata {
    name = "gp2"
    annotations {
      "storageclass.kubernetes.io/is-default-class" = true
    }
  }
  storage_provisioner = "kubernetes.io/aws-ebs"

  # reclaim_policy = "Retain"

  parameters {
    type = "gp2"
    fsType = "ext4"
  }
}
*/

