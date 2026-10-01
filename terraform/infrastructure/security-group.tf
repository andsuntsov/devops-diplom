resource "yandex_vpc_security_group" "kubernetes" {
  name        = "devops-diplom-kubernetes"
  description = "Security group for DevOps diploma Kubernetes nodes"
  network_id  = yandex_vpc_network.diplom.id

  ingress {
    protocol          = "ANY"
    description       = "Allow all traffic between Kubernetes nodes"
    predefined_target = "self_security_group"
  }

  ingress {
    protocol    = "TCP"
    description = "SSH access from administrator"
    v4_cidr_blocks = [
      "31.40.121.134/32",
      "16.170.195.186/32",
    ]
    port = 22
  }

  ingress {
    protocol       = "TCP"
    description    = "Kubernetes API"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 6443
  }

  ingress {
    protocol       = "TCP"
    description    = "Traefik NodePort from internet via NLB"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 30080
  }

  ingress {
    protocol          = "TCP"
    description       = "Yandex NLB health checks for Traefik"
    predefined_target = "loadbalancer_healthchecks"
    port              = 30080
  }

  egress {
    protocol       = "ANY"
    description    = "Allow outbound traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}
