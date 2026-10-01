#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "${ROOT}"

echo "========================================"
echo " DevOps Diplom reproducibility audit"
echo "========================================"

echo
echo "===== 1. GIT STATUS ====="

git status --short

echo
echo "===== 2. REQUIRED FILES ====="

required_files=(
  "terraform/bootstrap/versions.tf"
  "terraform/infrastructure/versions.tf"
  "terraform/infrastructure/compute.tf"
  "terraform/infrastructure/network.tf"
  "terraform/infrastructure/security-group.tf"
  "terraform/infrastructure/load-balancer.tf"
  "terraform/infrastructure/variables.tf"
  "ansible/version.env"
  "ansible/generate-inventory.sh"
  "ansible/install-cluster.sh"
  "kubernetes/app/namespace.yaml"
  "kubernetes/app/deployment.yaml"
  "kubernetes/app/service.yaml"
  "kubernetes/app/ingress.yaml"
  "kubernetes/app/ci-deployer-rbac.yaml"
  "kubernetes/app/create-ci-kubeconfig.sh"
  "kubernetes/traefik/version.env"
  "kubernetes/traefik/values.yaml"
  "kubernetes/traefik/install.sh"
  "kubernetes/app/create-ci-kubeconfig.sh"
  "monitoring/kube-prometheus/version.env"
  "monitoring/kube-prometheus/install.sh"
  "monitoring/kube-prometheus/configure-grafana-auth.sh"
  "monitoring/kube-prometheus/configure-grafana-public-url.sh"
  "kubernetes/monitoring/grafana-ingress.yaml"
  "kubernetes/monitoring/grafana-traefik-networkpolicy.yaml"
  ".github/workflows/terraform.yml"
  "README.md"
)

for file in "${required_files[@]}"; do
  if [ ! -f "${file}" ]; then
    echo "ERROR: missing ${file}"
    exit 1
  fi
done

echo "Required files: OK"

echo
echo "===== 3. SHELL SYNTAX ====="

shell_scripts=(
  "ansible/generate-inventory.sh"
  "ansible/install-cluster.sh"
  "kubernetes/traefik/install.sh"
  "monitoring/kube-prometheus/install.sh"
  "monitoring/kube-prometheus/configure-grafana-auth.sh"
  "monitoring/kube-prometheus/configure-grafana-public-url.sh"
)

for file in "${shell_scripts[@]}"; do
  bash -n "${file}"
done

echo "Shell syntax: OK"

echo
echo "===== 4. TERRAFORM FORMAT ====="

terraform fmt \
  -check \
  -recursive \
  terraform

echo "Terraform format: OK"

echo
echo "===== 5. TERRAFORM VALIDATION ====="

terraform \
  -chdir=terraform/bootstrap \
  init \
  -backend=false \
  -input=false \
  >/dev/null

terraform \
  -chdir=terraform/bootstrap \
  validate

terraform \
  -chdir=terraform/infrastructure \
  init \
  -backend=false \
  -input=false \
  >/dev/null

terraform \
  -chdir=terraform/infrastructure \
  validate

echo "Terraform validation: OK"

echo
echo "===== 6. KUBERNETES MANIFESTS ====="

manifests=(
  "kubernetes/app/namespace.yaml"
  "kubernetes/app/deployment.yaml"
  "kubernetes/app/service.yaml"
  "kubernetes/app/ingress.yaml"
  "kubernetes/app/ci-deployer-rbac.yaml"
  "kubernetes/monitoring/grafana-ingress.yaml"
  "kubernetes/monitoring/grafana-traefik-networkpolicy.yaml"
)

for file in "${manifests[@]}"; do
  kubectl apply \
    --dry-run=client \
    -f "${file}" \
    >/dev/null
done

echo "Kubernetes manifests: OK"

echo
echo "===== 7. KUBESPRAY ====="

# shellcheck disable=SC1091
source ansible/version.env

docker run \
  --rm \
  "${KUBESPRAY_IMAGE}" \
  ansible-playbook \
  --version \
  | head -n 1

INVENTORY_DIR="${ROOT}/ansible/inventory/devops-diplom"

docker run \
  --rm \
  --mount type=bind,source="${INVENTORY_DIR}",target=/inventory \
  "${KUBESPRAY_IMAGE}" \
  ansible-playbook \
  -i /inventory/inventory.ini \
  cluster.yml \
  --syntax-check \
  >/tmp/devops-diplom-kubespray-check.txt

grep \
  'playbook: cluster.yml' \
  /tmp/devops-diplom-kubespray-check.txt \
  >/dev/null

rm -f \
  /tmp/devops-diplom-kubespray-check.txt

echo "Kubespray: OK"

echo
echo "===== 8. TRAEFIK CHART ====="

# shellcheck disable=SC1091
source kubernetes/traefik/version.env

HELM_TMP="$(mktemp -d)"
trap 'rm -rf "${HELM_TMP}"' EXIT

HELM_REPOSITORY_CONFIG="${HELM_TMP}/repositories.yaml" \
HELM_REPOSITORY_CACHE="${HELM_TMP}/cache" \
helm repo add \
  "${TRAEFIK_HELM_REPOSITORY_NAME}" \
  "${TRAEFIK_HELM_REPOSITORY_URL}" \
  >/dev/null

HELM_REPOSITORY_CONFIG="${HELM_TMP}/repositories.yaml" \
HELM_REPOSITORY_CACHE="${HELM_TMP}/cache" \
helm repo update \
  "${TRAEFIK_HELM_REPOSITORY_NAME}" \
  >/dev/null

HELM_REPOSITORY_CONFIG="${HELM_TMP}/repositories.yaml" \
HELM_REPOSITORY_CACHE="${HELM_TMP}/cache" \
helm template \
  "${TRAEFIK_RELEASE}" \
  "${TRAEFIK_HELM_CHART}" \
  --namespace "${TRAEFIK_NAMESPACE}" \
  --version "${TRAEFIK_HELM_CHART_VERSION}" \
  --values kubernetes/traefik/values.yaml \
  >/dev/null

echo "Traefik chart: OK"

echo
echo "===== 9. SENSITIVE FILE AUDIT ====="

if git ls-files \
  | grep -Ei \
    '(^|/)(terraform-sa-key\.json|terraform-backend-credentials|admin\.conf|grafana-admin\.env|.*\.tfstate(\..*)?|local\.auto\.tfvars\.json)$'
then
  echo "ERROR: sensitive/generated files are tracked"
  exit 1
else
  echo "Sensitive tracked files: none"
fi

echo
echo "===== 10. GIT DIFF CHECK ====="

git diff --check

echo "Git diff: OK"

echo
echo "========================================"
echo " ALL REPRODUCIBILITY CHECKS PASSED"
echo "========================================"
