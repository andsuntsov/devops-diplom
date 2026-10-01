#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# shellcheck disable=SC1091
source "${SCRIPT_DIR}/version.env"

INVENTORY_DIR="${SCRIPT_DIR}/inventory/devops-diplom"
SSH_PRIVATE_KEY="${SSH_PRIVATE_KEY:-${HOME}/.ssh/devops-diplom}"

if [ ! -f "${SSH_PRIVATE_KEY}" ]; then
  echo "ERROR: SSH private key not found: ${SSH_PRIVATE_KEY}"
  exit 1
fi

echo "===== GENERATE INVENTORY ====="

"${SCRIPT_DIR}/generate-inventory.sh"

echo
echo "===== KUBESPRAY IMAGE ====="

echo "${KUBESPRAY_IMAGE}"

echo
echo "===== INSTALL KUBERNETES ====="

docker run \
  --rm \
  --mount type=bind,source="${INVENTORY_DIR}",target=/inventory \
  --mount type=bind,source="${SSH_PRIVATE_KEY}",target=/root/.ssh/id_rsa,readonly \
  --mount type=bind,source="${PROJECT_ROOT}",target=/workspace \
  --workdir /kubespray \
  "${KUBESPRAY_IMAGE}" \
  ansible-playbook \
  -i /inventory/inventory.ini \
  --private-key /root/.ssh/id_rsa \
  cluster.yml \
  -b

echo
echo "===== INSTALL KUBECONFIG ====="

ADMIN_CONF="${INVENTORY_DIR}/artifacts/admin.conf"
KUBECONFIG_DIR="${HOME}/.kube"
KUBECONFIG_FILE="${KUBECONFIG_DIR}/config"

if [ ! -f "${ADMIN_CONF}" ]; then
  echo "ERROR: Kubespray kubeconfig not found: ${ADMIN_CONF}"
  exit 1
fi

sudo chown   "$(id -u):$(id -g)"   "${ADMIN_CONF}"

chmod 600   "${ADMIN_CONF}"

mkdir -p   "${KUBECONFIG_DIR}"

chmod 700   "${KUBECONFIG_DIR}"

install   -m 600   "${ADMIN_CONF}"   "${KUBECONFIG_FILE}"

echo "Kubeconfig installed: ${KUBECONFIG_FILE}"

echo
echo "===== VERIFY KUBERNETES ====="

kubectl   --kubeconfig="${KUBECONFIG_FILE}"   get nodes

echo
echo "===== KUBERNETES INSTALL COMPLETE ====="
