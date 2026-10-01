resource "yandex_vpc_network" "diplom" {
  name        = "devops-diplom"
  description = "VPC network for DevOps diploma project"
}

resource "yandex_vpc_subnet" "subnet_a" {
  name           = "devops-diplom-a"
  description    = "Diploma subnet in ru-central1-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.diplom.id
  v4_cidr_blocks = ["10.10.1.0/24"]
}

resource "yandex_vpc_subnet" "subnet_b" {
  name           = "devops-diplom-b"
  description    = "Diploma subnet in ru-central1-b"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.diplom.id
  v4_cidr_blocks = ["10.10.2.0/24"]
}

resource "yandex_vpc_subnet" "subnet_d" {
  name           = "devops-diplom-d"
  description    = "Diploma subnet in ru-central1-d"
  zone           = "ru-central1-d"
  network_id     = yandex_vpc_network.diplom.id
  v4_cidr_blocks = ["10.10.3.0/24"]
}
