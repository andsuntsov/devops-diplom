resource "local_sensitive_file" "terraform_backend_credentials" {
  filename = "${path.module}/terraform-backend-credentials"

  content = <<-EOT
[terraform]
aws_access_key_id = ${yandex_iam_service_account_static_access_key.terraform.access_key}
aws_secret_access_key = ${yandex_iam_service_account_static_access_key.terraform.secret_key}
EOT

  file_permission = "0600"
}
