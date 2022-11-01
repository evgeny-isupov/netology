terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  token     = var.cloud_access_token
  cloud_id  = var.cloud_access_cloud_id
  folder_id = var.cloud_access_folder_id
  zone      = "ru-central1-c"
}

resource "yandex_compute_instance" vm {
  count = 2
  name = "terraform${count.index}"
  resources {
    cores  = 2
    memory = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = "fd8m8s42796gm6v7sf8e"
    }
  }

  network_interface {
    subnet_id = "b0ctjsl9bgitr16nf767"
    nat       = true
  }

    metadata = {
    user-data = "${file("./meta.txt")}"
  }

  scheduling_policy {
    preemptible = true
  }
}

resource "yandex_lb_target_group" "netology-1" {
  name = "netology-1"

  target {
    subnet_id = "b0ctjsl9bgitr16nf767"
    address = "${yandex_compute_instance.vm[0].network_interface.0.ip_address}"
  }
  target {
    subnet_id = "b0ctjsl9bgitr16nf767"
    address = "${yandex_compute_instance.vm[1].network_interface.0.ip_address}"
  }
}

resource "yandex_lb_network_load_balancer" "lb1" {
  name = "test-lb"
  listener {
    name = "my-listener"
    port = 80
  }
  attached_target_group {
    target_group_id = "${yandex_lb_target_group.netology-1.id}"
    healthcheck {
      name = "http"
        http_options {
          port = 80
          path = "/"
        }
    }
  }
}

output "internal_ip_address_vm_1" {
  value = yandex_compute_instance.vm[0].network_interface.0.ip_address
}
output "external_ip_address_vm_1" {
  value = yandex_compute_instance.vm[0].network_interface.0.nat_ip_address
}
output "internal_ip_address_vm_2" {
  value = yandex_compute_instance.vm[1].network_interface.0.ip_address
}
output "external_ip_address_vm_2" {
  value = yandex_compute_instance.vm[1].network_interface.0.nat_ip_address
}
