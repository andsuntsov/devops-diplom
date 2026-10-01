#!/usr/bin/env bash

set -euo pipefail
KUBE_VERSION_OVERRIDE="1.36.0"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TERRAFORM_DIR="${PROJECT_ROOT}/terraform/infrastructure"
INVENTORY_FILE="${PROJECT_ROOT}/ansible/inventory/devops-diplom/inventory.ini"

nodes_json="$(terraform -chdir="${TERRAFORM_DIR}" output -json kubernetes_nodes)"

master_name="$(jq -r '.master.name' <<< "${nodes_json}")"
master_external_ip="$(jq -r '.master.external_ip' <<< "${nodes_json}")"
master_internal_ip="$(jq -r '.master.internal_ip' <<< "${nodes_json}")"

worker_1_name="$(jq -r '.worker_1.name' <<< "${nodes_json}")"
worker_1_external_ip="$(jq -r '.worker_1.external_ip' <<< "${nodes_json}")"
worker_1_internal_ip="$(jq -r '.worker_1.internal_ip' <<< "${nodes_json}")"

worker_2_name="$(jq -r '.worker_2.name' <<< "${nodes_json}")"
worker_2_external_ip="$(jq -r '.worker_2.external_ip' <<< "${nodes_json}")"
worker_2_internal_ip="$(jq -r '.worker_2.internal_ip' <<< "${nodes_json}")"

cat > "${INVENTORY_FILE}" <<EOF_INVENTORY
[kube_control_plane]
${master_name} ansible_host=${master_external_ip} ip=${master_internal_ip} access_ip=${master_internal_ip} etcd_member_name=etcd1 ansible_user=ubuntu ansible_python_interpreter=/usr/bin/python3.12

[etcd:children]
kube_control_plane

[kube_node]
${worker_1_name} ansible_host=${worker_1_external_ip} ip=${worker_1_internal_ip} access_ip=${worker_1_internal_ip} ansible_user=ubuntu ansible_python_interpreter=/usr/bin/python3.12
${worker_2_name} ansible_host=${worker_2_external_ip} ip=${worker_2_internal_ip} access_ip=${worker_2_internal_ip} ansible_user=ubuntu ansible_python_interpreter=/usr/bin/python3.12
EOF_INVENTORY

echo "Inventory generated: ${INVENTORY_FILE}"

CLUSTER_OVERRIDES="${PROJECT_ROOT}/ansible/inventory/devops-diplom/group_vars/k8s_cluster/99-diplom.yml"

cat > "${CLUSTER_OVERRIDES}" <<EOF_OVERRIDES
---
kube_version: "__KUBE_VERSION__"

kubeconfig_localhost: true
kubeconfig_localhost_ansible_host: true
kubectl_localhost: false

supplementary_addresses_in_ssl_keys:
  - ${master_external_ip}
EOF_OVERRIDES

sed -i "s/__KUBE_VERSION__/${KUBE_VERSION_OVERRIDE:-1.36.4}/" "${CLUSTER_OVERRIDES}"

echo "Cluster overrides generated: ${CLUSTER_OVERRIDES}"
