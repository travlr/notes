terraform {
  backend "gcs" {
    bucket = "prodatalab-terraform-admin"
    path   = "/"
  }
}
