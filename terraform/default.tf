terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "0.213.0"
    }
  }
}


provider "yandex" {
    zone = "ru-central1-a"
    }


resource "yandex_vpc_network" "network-1" {
    name = "network-1"
}

resource "yandex_vpc_subnet" "network-subnet" {
    name           = "network-subnet"
    zone           = "ru-central1-a"
    network_id     = yandex_vpc_network.network-1.id
    v4_cidr_blocks = ["192.168.10.0/24"]
}


variable "user_name" {
  type        = string
  description = "Username for the VPS"
}


variable "ssh_key" {
  type        = string
  description = "SSH public key for the VPS"
}

resource "yandex_compute_instance" "linux-vm" {
  name = "terraform-vm"
  zone = "ru-central1-a"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      size = 20
      name = "boot-disk-1"
      type = "network-hdd"
      image_id = "fd842fimj1jg6vmfee6r"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.network-subnet.id
    nat       = true
  }
  metadata = {
    user-data = templatefile("${path.module}/meta.tpl", {
      user_name = var.user_name
      ssh_key  = var.ssh_key
    })
  }

}

resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/inventory.tpl", {
    vps_ip = yandex_compute_instance.linux-vm.network_interface.0.nat_ip_address
  })
  filename = "${path.module}/hosts.ini"
}


output "internal_ip_address" {
  value = yandex_compute_instance.linux-vm.network_interface.0.ip_address
}

output "external_ip_address" {
  value = yandex_compute_instance.linux-vm.network_interface.0.nat_ip_address
}
