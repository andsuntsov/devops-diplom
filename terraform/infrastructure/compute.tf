data "yandex_compute_image" "ubuntu" {
  family    = "ubuntu-2404-lts"
  folder_id = "standard-images"
}

resource "yandex_vpc_address" "master_public_ip" {
  external_ipv4_address {
    zone_id = "ru-central1-d"
  }
}

resource "yandex_compute_instance" "master" {
  name        = "k8s-master-1"
  hostname    = "k8s-master-1"
  description = "Kubernetes control plane for DevOps diploma"
  platform_id = "standard-v3"
  zone        = "ru-central1-d"

  allow_stopping_for_update = true

  resources {
    cores         = 2
    memory        = 4
    core_fraction = 50
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      type     = "network-hdd"
      size     = 20
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.subnet_d.id
    nat                = true
    nat_ip_address     = yandex_vpc_address.master_public_ip.external_ipv4_address[0].address
    security_group_ids = [yandex_vpc_security_group.kubernetes.id]
  }

  metadata = {
    ssh-keys = "ubuntu:${trimspace(var.ssh_public_key)}\n"
  }
}

resource "yandex_compute_instance" "worker_1" {
  name        = "k8s-worker-1"
  hostname    = "k8s-worker-1"
  description = "Kubernetes worker 1 for DevOps diploma"
  platform_id = "standard-v3"
  zone        = "ru-central1-a"

  allow_stopping_for_update = true

  resources {
    cores         = 2
    memory        = 4
    core_fraction = 100
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      type     = "network-hdd"
      size     = 20
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.subnet_a.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.kubernetes.id]
  }

  scheduling_policy {
    preemptible = true
  }

  metadata = {
    ssh-keys = "ubuntu:${trimspace(var.ssh_public_key)}\n"
  }
}

resource "yandex_compute_instance" "worker_2" {
  name        = "k8s-worker-2"
  hostname    = "k8s-worker-2"
  description = "Kubernetes worker 2 for DevOps diploma"
  platform_id = "standard-v3"
  zone        = "ru-central1-b"

  allow_stopping_for_update = true

  resources {
    cores         = 2
    memory        = 4
    core_fraction = 50
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      type     = "network-hdd"
      size     = 20
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.subnet_b.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.kubernetes.id]
  }

  scheduling_policy {
    preemptible = true
  }

  metadata = {
    ssh-keys = "ubuntu:${trimspace(var.ssh_public_key)}\n"
  }
}
