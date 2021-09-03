terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "3.82.0"
    }
  }
}

provider "google" {
  project = var.project_name
  region  = "us-west1"
  zone    = "us-west1-c"
}

resource "google_compute_network" "kubernetes-the-hard-way" {
  name                    = "kubernetes-the-hard-way"
  auto_create_subnetworks = false
  mtu                     = 1460
}

resource "google_compute_subnetwork" "kubernetes" {
  name          = "kubernetes"
  ip_cidr_range = "10.240.0.0/24"
  network       = google_compute_network.kubernetes-the-hard-way.id
}

resource "google_compute_firewall" "kubernetes-the-hard-way-allow-internal" {
  name    = "kubernetes-the-hard-way-allow-internal"
  network = google_compute_network.kubernetes-the-hard-way.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "udp"
  }

  source_ranges = ["10.240.0.0/24", "10.200.0.0/16"]
}

resource "google_compute_firewall" "kubernetes-the-hard-way-allow-external" {
  name    = "kubernetes-the-hard-way-allow-external"
  network = google_compute_network.kubernetes-the-hard-way.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22", "6443"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_address" "kubernetes-the-hard-way" {
  name       = "kubernetes-the-hard-way"
}

resource "google_service_account" "default" {
  account_id   = "service-account-id"
  display_name = "Service Account"
}

resource "google_compute_instance" "controllers" {
  count        = 3
  name         = "controller-${count.index}"
  machine_type = "e2-standard-2"
  #zone         = "us-central1-a"

  tags = ["kubernetes-the-hard-way", "controller"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
      size  = 200
    }
  }

  can_ip_forward = true

  network_interface {
    subnetwork    = google_compute_subnetwork.kubernetes.name
    network_ip = "10.240.0.1${count.index}"

    access_config {
      // Ephemeral public IP
    }
  }

  service_account {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    email  = google_service_account.default.email
    scopes = ["compute-rw", "storage-ro", "service-management", "service-control", "logging-write","monitoring"]
  }
}

resource "google_compute_instance" "workers" {
  count        = 3
  name         = "worker-${count.index}"
  machine_type = "e2-standard-2"
  #zone         = "us-central1-a"

  tags = ["kubernetes-the-hard-way", "worker"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
      size  = 200
    }
  }

  can_ip_forward = true

  network_interface {
    subnetwork    = google_compute_subnetwork.kubernetes.name
    network_ip = "10.240.0.2${count.index}"

    access_config {
      // Ephemeral public IP
    }
  }

  metadata = {
    "pod-cidr" = "10.200.${count.index}.0/24"
  }

  service_account {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    email  = google_service_account.default.email
    scopes = ["compute-rw", "storage-ro", "service-management", "service-control", "logging-write","monitoring"]
  }
}