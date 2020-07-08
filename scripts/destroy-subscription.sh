#!/usr/bin/env bash

OPERATOR_NAMESPACE="$1"

if [[ -z "${TMP_DIR}" ]]; then
  TMP_DIR=".tmp"
fi
mkdir -p "${TMP_DIR}"

YAML_FILE=${TMP_DIR}/kafka-subscription.yaml

set -e

echo "Removing kafka operator from ${OPERATOR_NAMESPACE} namespace"
kubectl delete -f ${YAML_FILE} -n "${OPERATOR_NAMESPACE}"

set +e

sleep 2
count=0
while kubectl get csv -n "${OPERATOR_NAMESPACE}" | grep -q strimzi-cluster-operator; do
  if [[ $count -eq 10 ]]; then
    echo "Timed out waiting for Kafka CSV to be deleted from ${OPERATOR_NAMESPACE}"
    exit 1
  fi

  echo "Waiting for Kafka CSV to be deleted from ${OPERATOR_NAMESPACE}"
  sleep 15
done
