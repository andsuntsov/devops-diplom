locals {
  terraform_sa_roles = toset([
    "compute.editor",
    "vpc.admin",
    "load-balancer.admin",
    "storage.editor",
  ])
}

resource "yandex_resourcemanager_folder_iam_member" "terraform_sa_roles" {
  for_each = local.terraform_sa_roles

  folder_id = data.yandex_client_config.client.folder_id
  role      = each.value
  member    = "serviceAccount:${yandex_iam_service_account.terraform.id}"
}
