output "cloud_id" {
  description = "Current Yandex Cloud ID"
  value       = data.yandex_client_config.client.cloud_id
}

output "folder_id" {
  description = "Current Yandex Cloud folder ID"
  value       = data.yandex_client_config.client.folder_id
}

output "zone" {
  description = "Default availability zone"
  value       = data.yandex_client_config.client.zone
}

output "vpc_id" {
  description = "DevOps diploma VPC ID"
  value       = yandex_vpc_network.diplom.id
}

output "kubernetes_security_group_id" {
  description = "Security group ID for Kubernetes nodes"
  value       = yandex_vpc_security_group.kubernetes.id
}

output "kubernetes_nodes" {
  description = "Kubernetes node connection information"

  value = {
    master = {
      name        = yandex_compute_instance.master.name
      zone        = yandex_compute_instance.master.zone
      internal_ip = yandex_compute_instance.master.network_interface[0].ip_address
      external_ip = yandex_compute_instance.master.network_interface[0].nat_ip_address
      role        = "control-plane"
    }

    worker_1 = {
      name        = yandex_compute_instance.worker_1.name
      zone        = yandex_compute_instance.worker_1.zone
      internal_ip = yandex_compute_instance.worker_1.network_interface[0].ip_address
      external_ip = yandex_compute_instance.worker_1.network_interface[0].nat_ip_address
      role        = "worker"
    }

    worker_2 = {
      name        = yandex_compute_instance.worker_2.name
      zone        = yandex_compute_instance.worker_2.zone
      internal_ip = yandex_compute_instance.worker_2.network_interface[0].ip_address
      external_ip = yandex_compute_instance.worker_2.network_interface[0].nat_ip_address
      role        = "worker"
    }
  }
}

output "traefik_load_balancer_ip" {
  description = "Public IPv4 address of the Traefik Network Load Balancer"
  value       = one(one(yandex_lb_network_load_balancer.traefik.listener).external_address_spec).address
}
