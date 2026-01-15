locals {
  project_id       = "<project-id>"
  network          = "default"
  image            = "ubuntu-2404-noble-amd64-v20251217" # Using ubuntu noble numbat lts
  ssh_user         = "ansible"
  private_key_path = "~/.ssh/ansible_rsa"

  web_servers = {
    docker-000-staging = {
      machine_type = "e2-micro"
      zone         = "asia-southeast2-a"
    }
  }
}

provider "google" {
  project     = local.project_id
  region      = "asia-southeast2"
  credentials = file("~/.config/gcloud/application_default_credentials.json")
}

resource "google_service_account" "docker" {
  account_id   = "docker-demo"
  display_name = "Docker Demo Service Account"
}

resource "google_compute_firewall" "web" {
  name     = "allow-http"
  network  = local.network
  priority = 1000

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges           = ["0.0.0.0/0"]
  target_service_accounts = [google_service_account.docker.email]
}

resource "google_compute_instance" "docker" {
  for_each     = local.web_servers
  name         = each.key
  machine_type = each.value.machine_type
  zone         = each.value.zone

  boot_disk {
    initialize_params {
      image = local.image
    }
  }

  network_interface {
    network = local.network
    access_config {}
  }

  service_account {
    email = google_service_account.docker.email
    scopes = [
      "cloud-platform"
    ]
  }

  provisioner "remote-exec" {
    inline = ["echo 'Wait till SSH is ready'"]

    connection {
      type        = "ssh"
      user        = local.ssh_user
      private_key = file(local.private_key_path)
      host        = self.network_interface.0.access_config.0.nat_ip
    }
  }

  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ${self.network_interface.0.access_config.0.nat_ip}, --private-key ${local.private_key_path} --user ${local.ssh_user} -e 'ansible_ssh_common_args=\"-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null\"' docker.yaml"
  }

  depends_on = [
    google_compute_instance.docker
  ]
}

output "docker_ip" {
  value = {
    for k, v in google_compute_instance.docker : k => "http://${v.network_interface.0.access_config.0.nat_ip}"
  }
}
