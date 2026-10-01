terraform {
  required_version = ">= 1.6.3"

  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.225"
    }
  }

  backend "s3" {
    endpoints = {
      s3 = "https://storage.yandexcloud.net"
    }

    bucket = "andsuntsov-devops-diplom-tfstate-b1gfh4gtufgm99vh51rg"
    region = "ru-central1"
    key    = "infrastructure/terraform.tfstate"

    shared_credentials_files = ["../bootstrap/terraform-backend-credentials"]
    profile                  = "terraform"

    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    skip_s3_checksum            = true
  }
}
