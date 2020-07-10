#!/usr/bin/env bash

NAMESPACE="$1"
NAME="$2"

if [[ -z "${NAME}" ]]; then
  NAME=kafka
fi

if [[ -z "${TMP_DIR}" ]]; then
  TMP_DIR=".tmp"
fi
mkdir -p "${TMP_DIR}"

YAML_FILE=${TMP_DIR}/kafka-instance-${NAME}.yaml

kubectl delete -f ${YAML_FILE} -n "${NAMESPACE}"

KAFKA_RESOURCE="statefulset/${NAME}-kafka"
ZOOKEEPER_RESOURCE="statefulset/${NAME}-zookeeper"

count=0
while kubectl get ${KAFKA_RESOURCE} -n "${NAMESPACE}" 1> /dev/null 2> /dev/null; do
  if [[ ${count} -eq 12 ]]; then
    echo "Timed out waiting for ${KAFKA_RESOURCE} to be removed"
    exit 1
  else
    count=$((count + 1))
  fi

  echo "Waiting for ${KAFKA_RESOURCE} to be removed"
  sleep 30
done

count=0
while kubectl get ${ZOOKEEPER_RESOURCE} -n "${NAMESPACE}" 1> /dev/null 2> /dev/null; do
  if [[ ${count} -eq 12 ]]; then
    echo "Timed out waiting for ${ZOOKEEPER_RESOURCE} to be removed"
    exit 1
  else
    count=$((count + 1))
  fi

  echo "Waiting for ${ZOOKEEPER_RESOURCE} to be removed"
  sleep 30
done
