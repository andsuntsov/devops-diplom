#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SECRETS_DIR="${SCRIPT_DIR}/secrets"
SECRET_FILE="${SECRETS_DIR}/grafana-admin.env"

mkdir -p "${SECRETS_DIR}"
chmod 700 "${SECRETS_DIR}"

if [ ! -f "${SECRET_FILE}" ]; then
  umask 077

  GRAFANA_PASSWORD="$(openssl rand -hex 24)"

  cat > "${SECRET_FILE}" <<EOF_SECRET
GF_SECURITY_ADMIN_USER=admin
GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_PASSWORD}
EOF_SECRET

  unset GRAFANA_PASSWORD
fi

chmod 600 "${SECRET_FILE}"

kubectl create secret generic grafana-admin \
  -n monitoring \
  --from-env-file="${SECRET_FILE}" \
  --dry-run=client \
  -o yaml \
  | kubectl apply -f -

kubectl set env \
  -n monitoring \
  deployment/grafana \
  --from=secret/grafana-admin

kubectl rollout restart \
  -n monitoring \
  deployment/grafana

kubectl rollout status \
  -n monitoring \
  deployment/grafana \
  --timeout=120s
