provider "yandex" {
  service_account_key_file = fileexists("${path.module}/../bootstrap/terraform-sa-key.json") ? "${path.module}/../bootstrap/terraform-sa-key.json" : null

  cloud_id  = "b1g7qqt47mrjbo1pon6o"
  folder_id = "b1gfh4gtufgm99vh51rg"
  zone      = "ru-central1-d"
}
