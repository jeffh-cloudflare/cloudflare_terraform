resource "random_id" "namespace" {
  prefix      = "desktop-"
  byte_length = 2
}


data "google_compute_image" "os" {
  # Ubuntu 20.04 
  family  = "ubuntu-2004-lts"
  project = "ubuntu-os-cloud"
}

resource "google_compute_instance" "desktop" {
  name         = random_id.namespace.hex
  machine_type = var.machine_type
  zone         = var.zone
  tags         = ["desktop", "ssh"]

  boot_disk {
    initialize_params {
        image = data.google_compute_image.os.self_link
    }
  }

  network_interface {
    network = "default"
    access_config {
      // Ephemeral IP
    }
  }

  scheduling {
    preemptible       = true
    automatic_restart = false
  }

  metadata_startup_script = data.template_file.desktop_config.rendered

  metadata = {
    "cf-terraform" = "zt_desktop"
    "cf-email"     = var.cloudflare_email
  }
}

data "template_file" "desktop_config" {
    template = file("${path.module}/scripts/desktop_script.sh")
    vars = {
        CRD          = var.chrome_remote_desktop
        DESKTOP_USER = var.user
        PIN          = var.pin
    }
}

output "build_time" {
  value = "Typically it takes ~8 minutes for the script to finish running to create the desktop. Once the desktop reboots you should see it in Chrome Remote Desktop."
}

output "desktop_name" {
  value = random_id.namespace.hex
}

output "post_config" {
  value = "Run 'warp-cli --accept-tos teams-enroll <team name>' on the remote server and the DISPLAY command when the desktop finishes"
}