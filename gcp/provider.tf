provider google-beta {
  region  = "${var.region}"
  project = "${var.project}"
}

terraform {
  backend "gcs" {
    bucket = "tf-state-ian"
    prefix = "terraform/state"
  }
}
