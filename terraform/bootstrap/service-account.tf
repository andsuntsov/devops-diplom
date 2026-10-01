resource "yandex_iam_service_account" "terraform" {
  name        = "diploma-terraform-sa"
  description = "Service account for Terraform diploma infrastructure"
}
