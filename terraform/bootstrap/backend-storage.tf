resource "yandex_iam_service_account_static_access_key" "terraform" {
  service_account_id = yandex_iam_service_account.terraform.id
  description        = "Static access key for Terraform state backend"
}

resource "yandex_storage_bucket" "terraform_state" {
  bucket    = "andsuntsov-devops-diplom-tfstate-b1gfh4gtufgm99vh51rg"
  folder_id = data.yandex_client_config.client.folder_id

  access_key = yandex_iam_service_account_static_access_key.terraform.access_key
  secret_key = yandex_iam_service_account_static_access_key.terraform.secret_key

  force_destroy = true
}
