resource "yandex_iam_service_account_key" "terraform" {
  service_account_id = yandex_iam_service_account.terraform.id
  description        = "Authorized key for Terraform provider authentication"
  key_algorithm      = "RSA_2048"
}

resource "local_sensitive_file" "terraform_sa_key" {
  filename = "${path.module}/terraform-sa-key.json"

  content = jsonencode({
    id                 = yandex_iam_service_account_key.terraform.id
    service_account_id = yandex_iam_service_account_key.terraform.service_account_id
    created_at         = yandex_iam_service_account_key.terraform.created_at
    key_algorithm      = yandex_iam_service_account_key.terraform.key_algorithm
    public_key         = yandex_iam_service_account_key.terraform.public_key
    private_key        = yandex_iam_service_account_key.terraform.private_key
  })

  file_permission = "0600"
}
