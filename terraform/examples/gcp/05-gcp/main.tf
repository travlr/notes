variable region {
  default = "us-central1"
}

variable zone {
  default = "us-central1-b"
}

provider google {
  version = "~> 1.1"
  region  = "${var.region}"
}

provider template {
  version = "~> 1.0"
}

provider "null" {
  version = "~> 1.0"
}

data "template_file" "group1-startup-script" {
  template = "${file("${format("%s/../scripts/gceme.sh.tpl", path.module)}")}"

  vars {
    PROXY_PATH = ""
  }
}

module "mig1" {
  source            = "github.com/GoogleCloudPlatform/terraform-google-managed-instance-group"
  region            = "${var.region}"
  zone              = "${var.zone}"
  name              = "group1"
  size              = 2
  service_port      = 80
  service_port_name = "http"
  target_pools      = ["${module.gce-lb-fr.target_pool}"]
  target_tags       = ["allow-service1"]
  startup_script    = "${data.template_file.group1-startup-script.rendered}"
}

module "gce-lb-fr" {
  source       = "github.com/GoogleCloudPlatform/terraform-google-lb"
  region       = "${var.region}"
  name         = "group1-lb"
  service_port = "${module.mig1.service_port}"
  target_tags  = ["${module.mig1.target_tags}"]
}
