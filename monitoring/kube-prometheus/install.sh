#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1091
source "${SCRIPT_DIR}/version.env"

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "${WORK_DIR}"' EXIT

echo "===== FETCH KUBE-PROMETHEUS ====="

git clone \
  --quiet \
  "${KUBE_PROMETHEUS_REPOSITORY}" \
  "${WORK_DIR}/kube-prometheus"

git -C "${WORK_DIR}/kube-prometheus" \
  checkout --quiet "${KUBE_PROMETHEUS_COMMIT}"

echo "Commit: $(git -C "${WORK_DIR}/kube-prometheus" rev-parse HEAD)"

echo
echo "===== INSTALL CRDS / SETUP ====="

kubectl apply \
  --server-side \
  -f "${WORK_DIR}/kube-prometheus/manifests/setup"

echo
echo "===== WAIT FOR PROMETHEUS CRDS ====="

mapfile -t PROMETHEUS_CRDS < <(
  grep -h '^  name: .*\.monitoring\.coreos\.com$' \
    "${WORK_DIR}/kube-prometheus/manifests/setup/"*CustomResourceDefinition.yaml \
    | awk '{print $2}' \
    | sort -u
)

if [ "${#PROMETHEUS_CRDS[@]}" -eq 0 ]; then
  echo "ERROR: Prometheus Operator CRDs were not found"
  exit 1
fi

for crd in "${PROMETHEUS_CRDS[@]}"; do
  echo "Waiting for CRD: ${crd}"

  kubectl wait \
    --for=condition=Established \
    --timeout=120s \
    "customresourcedefinition/${crd}"
done

echo
echo "===== INSTALL KUBE-PROMETHEUS ====="

kubectl apply \
  --server-side \
  -f "${WORK_DIR}/kube-prometheus/manifests"

echo
echo "===== SCALE PROMETHEUS TO 1 ====="

kubectl patch prometheus k8s \
  -n monitoring \
  --type=merge \
  --patch-file "${SCRIPT_DIR}/patches/prometheus.yaml"

echo
echo "===== SCALE ALERTMANAGER TO 1 ====="

kubectl patch alertmanager main \
  -n monitoring \
  --type=merge \
  --patch-file "${SCRIPT_DIR}/patches/alertmanager.yaml"

echo
echo "===== ADAPT PROMETHEUS PDB ====="

kubectl patch poddisruptionbudget prometheus-k8s \
  -n monitoring \
  --type=merge \
  --patch-file "${SCRIPT_DIR}/patches/prometheus-pdb.yaml"

echo
echo "===== INSTALL COMPLETE ====="
