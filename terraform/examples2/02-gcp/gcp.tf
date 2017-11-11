provider "google" {
  credentials = "${file("gcp-credentials.json")}"
  project     = "elastic-byte"
  region      = "us-west1"
  version     = "~> 1.1"
}
