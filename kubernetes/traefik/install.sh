#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1091
source "${SCRIPT_DIR}/version.env"

echo "===== ADD TRAEFIK HELM REPOSITORY ====="

helm repo add \
  "${TRAEFIK_HELM_REPOSITORY_NAME}" \
  "${TRAEFIK_HELM_REPOSITORY_URL}" \
  --force-update

helm repo update \
  "${TRAEFIK_HELM_REPOSITORY_NAME}"

echo
echo "===== INSTALL TRAEFIK ====="

helm upgrade \
  --install \
  "${TRAEFIK_RELEASE}" \
  "${TRAEFIK_HELM_CHART}" \
  --namespace "${TRAEFIK_NAMESPACE}" \
  --create-namespace \
  --version "${TRAEFIK_HELM_CHART_VERSION}" \
  --values "${SCRIPT_DIR}/values.yaml" \
  --wait \
  --timeout 5m

echo
echo "===== VERIFY TRAEFIK ====="

kubectl get pods \
  --namespace "${TRAEFIK_NAMESPACE}"

kubectl get service \
  --namespace "${TRAEFIK_NAMESPACE}" \
  "${TRAEFIK_RELEASE}"

echo
echo "===== TRAEFIK INSTALL COMPLETE ====="
