terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.13"
    }
  }

  required_version = ">= 0.13"
}
// Configure the Yandex Cloud Provider (Basic)
//
provider "yandex" {
  token     = "y0__xDp17ICGMHdEyDZlYPaE6oOaUU3fGGY1-SZRpw9rbEgUVcA"
  cloud_id  = "b1g21ko4q22qq9nssbl1"
  folder_id = "b1ghfja4e1sdv347eqa6"
  zone      = "ru-central1-d"
}

// Create a new Compute Instance
//
resource "yandex_compute_instance" "default" {
  name        = "compute-vm-yc"
  platform_id = "standard-v3"
  zone        = "ru-central1-d"

  resources {
    cores  = 2
    memory = 2
    core_fraction = 50
  }

  boot_disk {
    disk_id = yandex_compute_disk.boot-disk.id
  }

  network_interface {
    index     = 1
    subnet_id = yandex_vpc_subnet.default-ru-central1-d.id
    //nat_ip_version = ipv4
    nat = true
    ipv4 = true
  }

  metadata = {
    foo      = "bar"
    ssh-keys = "ubuntu:${file("~/.ssh/id_ed25519.pub")}"
  }
}

// Auxiliary resources for Compute Instance
resource "yandex_vpc_network" "default" {}

resource "yandex_vpc_subnet" "default-ru-central1-d" {
  zone           = "ru-central1-d"
  network_id     = yandex_vpc_network.default.id
  v4_cidr_blocks = ["10.130.0.0/24"]
}
// Create a new Compute Disk.
//
resource "yandex_compute_disk" "boot-disk" {
  name     = "boot"
  size     =  6
  type     = "network-ssd"
  zone     = "ru-central1-d"
}