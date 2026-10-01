#!/usr/bin/env bash

set -euo pipefail

NAMESPACE="devops-diplom"
SERVICE_ACCOUNT="github-actions-deployer"
TOKEN_SECRET="github-actions-deployer-token"
OUTPUT="${1:-/tmp/devops-diplom-ci-kubeconfig}"

umask 077

echo "===== WAIT FOR SERVICE ACCOUNT TOKEN ====="

TOKEN_BASE64=""

for attempt in {1..30}; do
  TOKEN_BASE64="$(
    kubectl get secret \
      "${TOKEN_SECRET}" \
      --namespace "${NAMESPACE}" \
      --output jsonpath='{.data.token}' \
      2>/dev/null || true
  )"

  if [ -n "${TOKEN_BASE64}" ]; then
    break
  fi

  sleep 2
done

if [ -z "${TOKEN_BASE64}" ]; then
  echo "ERROR: service account token is not available"
  exit 1
fi

echo "Token is ready."

echo
echo "===== BUILD RESTRICTED KUBECONFIG ====="

API_SERVER="$(
  kubectl config view \
    --minify \
    --output jsonpath='{.clusters[0].cluster.server}'
)"

CA_BASE64="$(
  kubectl get secret \
    "${TOKEN_SECRET}" \
    --namespace "${NAMESPACE}" \
    --output jsonpath='{.data.ca\.crt}'
)"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

printf '%s' "${CA_BASE64}" \
  | base64 --decode \
  > "${TMP_DIR}/ca.crt"

CI_TOKEN="$(
  printf '%s' "${TOKEN_BASE64}" \
    | base64 --decode
)"

rm -f "${OUTPUT}"

kubectl config \
  --kubeconfig="${OUTPUT}" \
  set-cluster devops-diplom \
  --server="${API_SERVER}" \
  --certificate-authority="${TMP_DIR}/ca.crt" \
  --embed-certs=true \
  >/dev/null

kubectl config \
  --kubeconfig="${OUTPUT}" \
  set-credentials "${SERVICE_ACCOUNT}" \
  --token="${CI_TOKEN}" \
  >/dev/null

kubectl config \
  --kubeconfig="${OUTPUT}" \
  set-context "${SERVICE_ACCOUNT}" \
  --cluster=devops-diplom \
  --user="${SERVICE_ACCOUNT}" \
  --namespace="${NAMESPACE}" \
  >/dev/null

kubectl config \
  --kubeconfig="${OUTPUT}" \
  use-context "${SERVICE_ACCOUNT}" \
  >/dev/null

chmod 600 "${OUTPUT}"

unset CI_TOKEN
unset TOKEN_BASE64

echo "Created: ${OUTPUT}"

echo
echo "===== VERIFY RESTRICTED ACCESS ====="

if KUBECONFIG="${OUTPUT}" \
  kubectl auth can-i \
  patch deployment/devops-diplom-app \
  --namespace "${NAMESPACE}" \
  >/dev/null
then
  echo "patch app deployment: yes"
else
  echo "ERROR: patch app deployment: no"
  exit 1
fi

if KUBECONFIG="${OUTPUT}" \
  kubectl auth can-i \
  delete deployment/devops-diplom-app \
  --namespace "${NAMESPACE}" \
  >/dev/null
then
  echo "ERROR: delete app deployment: yes"
  exit 1
else
  echo "delete app deployment: no"
fi
