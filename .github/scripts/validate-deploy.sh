#!/usr/bin/env bash

SCRIPT_DIR=$(cd $(dirname "$0"); pwd -P)

export KUBECONFIG="${SCRIPT_DIR}/.kube/config"

CLUSTER_TYPE="$1"
NAMESPACE="$2"

echo "Verifying resources in $NAMESPACE namespace"

# TODO: For now we will exclude Pending status from failed statuses. Need to revisit
PODS=$(kubectl get -n "${NAMESPACE}" pods -o jsonpath='{range .items[*]}{.status.phase}{": "}{.kind}{"/"}{.metadata.name}{"\n"}{end}' | grep -v "Running" | grep -v "Succeeded" | grep -v "Pending")
POD_STATUSES=$(echo "${PODS}" | sed -E "s/(.*):.*/\1/g")
if [[ -n "${POD_STATUSES}" ]]; then
  echo "  Pods have non-success statuses: ${PODS}"
  exit 1
fi
