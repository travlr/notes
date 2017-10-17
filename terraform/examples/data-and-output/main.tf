data "google_compute_zones" "available" {}

output "project_id" {
  value = "${data.google_compute_zones.available.names}"
}
