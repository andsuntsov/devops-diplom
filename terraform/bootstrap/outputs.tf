output "terraform_service_account_id" {
  description = "Service account ID used by Terraform"
  value       = yandex_iam_service_account.terraform.id
}

output "terraform_state_bucket" {
  description = "Object Storage bucket for Terraform remote state"
  value       = yandex_storage_bucket.terraform_state.bucket
}

output "terraform_state_access_key" {
  description = "Static access key ID for Terraform state backend"
  value       = yandex_iam_service_account_static_access_key.terraform.access_key
  sensitive   = true
}

output "terraform_state_secret_key" {
  description = "Static secret key for Terraform state backend"
  value       = yandex_iam_service_account_static_access_key.terraform.secret_key
  sensitive   = true
}
