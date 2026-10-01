# DevOps Diplom

Дипломный проект по автоматизации развёртывания облачной инфраструктуры, Kubernetes-кластера, мониторинга и CI/CD в Yandex Cloud.

## Результат

Проект включает:

- инфраструктуру, описанную в Terraform, с удалённым хранением state-файла в Yandex Object Storage;
- Kubernetes-кластер из трёх виртуальных машин, установленный с помощью Kubespray;
- внешний доступ через Traefik и Yandex Network Load Balancer;
- тестовое приложение в отдельном репозитории и Docker-образ в GitHub Container Registry (GHCR);
- мониторинг на базе Prometheus, Grafana, Alertmanager, node-exporter и kube-state-metrics;
- CI/CD для Terraform и тестового приложения с помощью GitHub Actions.

## Архитектура

```text
Internet
   |
   v
Yandex Network Load Balancer :80
   |
   v
Traefik NodePort :30080
   |
   +-- /         -> devops-diplom-app
   |
   +-- /grafana  -> Grafana

Kubernetes:
- 1 control-plane-нода
- 2 worker-ноды
- Calico CNI
- containerd
```

## Структура репозитория

```text
terraform/
  bootstrap/         сервисный аккаунт и backend Terraform
  infrastructure/    VPC, подсети, Security Group, VM и Network Load Balancer

ansible/
  inventory/         inventory-файл и переменные Kubespray
  generate-inventory.sh
  install-cluster.sh
  version.env

kubernetes/
  app/               Deployment, Service, Ingress и RBAC для CI/CD
  traefik/           values и установка Traefik
  monitoring/        Ingress и NetworkPolicy для Grafana

monitoring/
  kube-prometheus/   установка и настройка мониторинга

scripts/
  verify-reproducibility.sh
```

## Terraform

Bootstrap-конфигурация и основная инфраструктура находятся в разных каталогах.

`terraform/bootstrap` создаёт:

- сервисный аккаунт Terraform с необходимыми правами;
- бакет Yandex Object Storage для удалённого state-файла;
- авторизованный ключ сервисного аккаунта;
- учётные данные для S3-бэкенда.

После выполнения bootstrap локально создаются:

```text
terraform/bootstrap/terraform-sa-key.json
terraform/bootstrap/terraform-backend-credentials
```

Эти файлы исключены из отслеживания Git.

Основная инфраструктура находится в `terraform/infrastructure`. Её state-файл хранится удалённо в Yandex Object Storage.

## Kubernetes

Кластер устанавливается с помощью Kubespray. Версия используемого образа зафиксирована в:

```text
ansible/version.env
```

Установка:

```bash
./ansible/install-cluster.sh
```

Скрипт формирует inventory-файл на основе выходных значений Terraform, запускает зафиксированную версию Kubespray в Docker, устанавливает созданный kubeconfig в `~/.kube/config` и проверяет доступность нод.

Проверка кластера:

```bash
kubectl get nodes
kubectl get pods --all-namespaces
```

Текущая версия Kubernetes:

```text
v1.36.0
```

## Traefik и внешний доступ

Версия Helm-чарта Traefik зафиксирована в:

```text
kubernetes/traefik/version.env
```

Установка:

```bash
./kubernetes/traefik/install.sh
```

Получить публичный IP Yandex Network Load Balancer:

```bash
terraform -chdir=terraform/infrastructure output -raw traefik_load_balancer_ip
```

Текущие публичные адреса:

```text
Приложение: http://158.160.241.195/
Grafana:     http://158.160.241.195/grafana/
```

После пересоздания инфраструктуры адрес можно получить командой Terraform выше.

## Тестовое приложение

Репозиторий:

```text
https://github.com/andsuntsov/devops-diplom-app
```

Docker-образ:

```text
ghcr.io/andsuntsov/devops-diplom-app:v1.0.1
```

Первичное развёртывание:

```bash
kubectl apply -f kubernetes/app/namespace.yaml
kubectl apply -f kubernetes/app/deployment.yaml
kubectl apply -f kubernetes/app/service.yaml
kubectl apply -f kubernetes/app/ingress.yaml
```

## Мониторинг

Используется kube-prometheus с зафиксированной ревизией.

Установка и настройка:

```bash
./monitoring/kube-prometheus/install.sh
./monitoring/kube-prometheus/configure-grafana-auth.sh
./monitoring/kube-prometheus/configure-grafana-public-url.sh

kubectl apply -f kubernetes/monitoring/grafana-traefik-networkpolicy.yaml
kubectl apply -f kubernetes/monitoring/grafana-ingress.yaml
```

Пароль администратора Grafana генерируется автоматически и сохраняется только локально:

```text
monitoring/kube-prometheus/secrets/grafana-admin.env
```

Файл исключён из Git. Логин Grafana — `admin`. Пароль для проверки предоставляется отдельно.

## CI/CD для Terraform

Workflow:

```text
.github/workflows/terraform.yml
```

Для pull request в ветку `main` выполняется:

```text
fmt -> init -> validate -> plan
```

Для push в ветку `main`:

```text
fmt -> init -> validate -> plan -> apply
```

Используются секреты GitHub Actions:

```text
YC_SERVICE_ACCOUNT_KEY_JSON
TF_BACKEND_CREDENTIALS
TF_VAR_SSH_PUBLIC_KEY
```

Пример pull request:

```text
https://github.com/andsuntsov/devops-diplom/pull/1
```

## CI/CD тестового приложения

Workflow находится в репозитории `devops-diplom-app`.

При push в ветку `main`:

```text
smoke-тест -> сборка -> публикация :latest в GHCR
```

При создании тега `vX.Y.Z`:

```text
smoke-тест -> сборка -> публикация :vX.Y.Z -> деплой :vX.Y.Z в Kubernetes
```

Для деплоя используется отдельный ServiceAccount с ограниченными правами в namespace `devops-diplom`.

Создать RBAC:

```bash
kubectl apply -f kubernetes/app/ci-deployer-rbac.yaml
```

Создать ограниченный kubeconfig:

```bash
./kubernetes/app/create-ci-kubeconfig.sh /tmp/devops-diplom-ci-kubeconfig
```

Содержимое созданного kubeconfig необходимо сохранить в секрете GitHub Actions `KUBE_CONFIG` репозитория `devops-diplom-app`, после чего временный файл удалить.

## Развёртывание с нуля

### 1. Предварительные требования

На рабочей машине должны быть установлены:

- Terraform;
- Yandex Cloud CLI с выполненной авторизацией;
- Docker;
- kubectl;
- Helm;
- jq;
- Git;
- OpenSSH;
- GitHub CLI — если требуется настроить секреты GitHub Actions.

Для `terraform init` необходим доступ к `registry.terraform.io`.

### 2. Клонирование репозитория

```bash
git clone https://github.com/andsuntsov/devops-diplom.git
cd devops-diplom
```

### 3. Bootstrap-конфигурация Terraform

```bash
terraform -chdir=terraform/bootstrap init
terraform -chdir=terraform/bootstrap plan
terraform -chdir=terraform/bootstrap apply
```

### 4. SSH-ключ для виртуальных машин

Если ключ ещё не создан:

```bash
ssh-keygen -t ed25519 -f ~/.ssh/devops-diplom -N ''
```

Передать публичный SSH-ключ Terraform:

```bash
jq -n   --arg ssh_public_key "$(cat ~/.ssh/devops-diplom.pub)"   '{ssh_public_key: $ssh_public_key}'   > terraform/infrastructure/local.auto.tfvars.json
```

`local.auto.tfvars.json` исключён из Git.

### 5. Создание основной инфраструктуры

```bash
terraform -chdir=terraform/infrastructure init
terraform -chdir=terraform/infrastructure plan
terraform -chdir=terraform/infrastructure apply
```

### 6. Установка Kubernetes и Traefik

```bash
./ansible/install-cluster.sh
./kubernetes/traefik/install.sh
```

### 7. Развёртывание приложения

```bash
kubectl apply -f kubernetes/app/namespace.yaml
kubectl apply -f kubernetes/app/deployment.yaml
kubectl apply -f kubernetes/app/service.yaml
kubectl apply -f kubernetes/app/ingress.yaml
kubectl apply -f kubernetes/app/ci-deployer-rbac.yaml
```

### 8. Установка мониторинга

```bash
./monitoring/kube-prometheus/install.sh
./monitoring/kube-prometheus/configure-grafana-auth.sh
./monitoring/kube-prometheus/configure-grafana-public-url.sh
kubectl apply -f kubernetes/monitoring/grafana-traefik-networkpolicy.yaml
kubectl apply -f kubernetes/monitoring/grafana-ingress.yaml
```

### 9. Настройка секретов Terraform CI/CD

```bash
gh secret set YC_SERVICE_ACCOUNT_KEY_JSON   --repo andsuntsov/devops-diplom   < terraform/bootstrap/terraform-sa-key.json

gh secret set TF_BACKEND_CREDENTIALS   --repo andsuntsov/devops-diplom   < terraform/bootstrap/terraform-backend-credentials

gh secret set TF_VAR_SSH_PUBLIC_KEY   --repo andsuntsov/devops-diplom   < ~/.ssh/devops-diplom.pub
```

### 10. Настройка доступа CD приложения к Kubernetes

```bash
./kubernetes/app/create-ci-kubeconfig.sh /tmp/devops-diplom-ci-kubeconfig

gh secret set KUBE_CONFIG   --repo andsuntsov/devops-diplom-app   < /tmp/devops-diplom-ci-kubeconfig

rm -f /tmp/devops-diplom-ci-kubeconfig
```

## Проверка воспроизводимости

Неразрушающие проверки собраны в одной команде:

```bash
./scripts/verify-reproducibility.sh
```

Скрипт проверяет обязательные файлы, синтаксис shell-скриптов, форматирование и валидацию Terraform, Kubernetes-манифесты, Kubespray, Helm-чарт Traefik, отсутствие отслеживаемых конфиденциальных или сгенерированных файлов и `git diff --check`.

Скрипт не выполняет `terraform apply`, не устанавливает Kubernetes и не изменяет работающий кластер.

Успешный результат:

```text
ALL REPRODUCIBILITY CHECKS PASSED
```

## Репозитории

Инфраструктура и Kubernetes:

```text
https://github.com/andsuntsov/devops-diplom
```

Тестовое приложение:

```text
https://github.com/andsuntsov/devops-diplom-app
```

Docker-образ:

```text
ghcr.io/andsuntsov/devops-diplom-app:v1.0.1
```
