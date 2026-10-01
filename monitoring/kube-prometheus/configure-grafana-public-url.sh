#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

NLB_IP="$(
  terraform \
    -chdir="${REPO_ROOT}/terraform/infrastructure" \
    output -raw traefik_load_balancer_ip
)"

GRAFANA_ROOT_URL="http://${NLB_IP}/grafana/"

echo "Grafana root URL: ${GRAFANA_ROOT_URL}"

kubectl set env \
  -n monitoring \
  deployment/grafana \
  GF_SERVER_ROOT_URL="${GRAFANA_ROOT_URL}" \
  GF_SERVER_SERVE_FROM_SUB_PATH=true

kubectl rollout status \
  -n monitoring \
  deployment/grafana \
  --timeout=120s
