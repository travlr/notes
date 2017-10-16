resource "google_compute_disk" "blog" {
  name     = "blog"
  type     = "pd-ssd"
  zone     = "us-west1-a"
  snapshot = "blog-2017-02-09-1"
  size     = 10
}

resource "google_compute_instance" "blog" {
  name         = "blog"
  machine_type = "f1-micro"
  zone         = "${google_compute_disk.blog.zone}"
  tags         = ["http"]

  boot_disk {
    source      = "${google_compute_disk.blog.name}"
    auto_delete = true
  }

  network_interface {
    network = "default"

    access_config {
      # ephemeral external ip addr
    }
  }

  metadata {}

  scheduling {
    preemptible         = false
    on_host_maintenance = "MIGRATE"
    automatic_restart   = true
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'hello from $HOSTNAME' > ~/terraform_complete",
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = "${file("~/.ssh/google_compute_engine")}"
    }
  }
}
