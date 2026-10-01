resource "yandex_lb_target_group" "traefik" {
  name = "devops-diplom-traefik"

  target {
    subnet_id = yandex_vpc_subnet.subnet_a.id
    address   = yandex_compute_instance.worker_1.network_interface[0].ip_address
  }

  target {
    subnet_id = yandex_vpc_subnet.subnet_b.id
    address   = yandex_compute_instance.worker_2.network_interface[0].ip_address
  }
}

resource "yandex_lb_network_load_balancer" "traefik" {
  name = "devops-diplom-traefik"
  type = "external"

  listener {
    name        = "http"
    port        = 80
    target_port = 30080
    protocol    = "tcp"

    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_lb_target_group.traefik.id

    healthcheck {
      name                = "http"
      interval            = 5
      timeout             = 2
      healthy_threshold   = 2
      unhealthy_threshold = 2

      http_options {
        port = 30080
        path = "/"
      }
    }
  }
}
