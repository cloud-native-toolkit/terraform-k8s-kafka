#!/usr/bin/env bash

CLUSTER_TYPE="$1"
NAMESPACE="$2"
INGRESS_SUBDOMAIN="$3"
NAME="$4"
TLS_SECRET_NAME="$5"

if [[ -z "${NAME}" ]]; then
  NAME=kafka
fi

if [[ -z "${TLS_SECRET_NAME}" ]]; then
  TLS_SECRET_NAME=$(echo "${INGRESS_SUBDOMAIN}" | sed -E "s/([^.]+).*/\1/g")
fi

if [[ -z "${TMP_DIR}" ]]; then
  TMP_DIR=".tmp"
fi
mkdir -p "${TMP_DIR}"

HOST="${NAME}-${NAMESPACE}.${INGRESS_SUBDOMAIN}"

if [[ "${CLUSTER_TYPE}" == "kubernetes" ]]; then
  TYPE="ingress"
else
  TYPE="route"
fi

YAML_FILE=${TMP_DIR}/kafka-instance-${NAME}.yaml

cat <<EOL > ${YAML_FILE}
apiVersion: kafka.strimzi.io/v1beta1
kind: Kafka
metadata:
  name: ${NAME}
spec:
  kafka:
    version: 2.4.0
    replicas: 3
    listeners:
      external:
        authentication:
          type: tls
        configuration:
          bootstrap:
            host: ${HOST}
          brokers:
          - broker: 0
            host: broker-0-${NAMESPACE}.${INGRESS_SUBDOMAIN}
          - broker: 1
            host: broker-1-${NAMESPACE}.${INGRESS_SUBDOMAIN}
          - broker: 2
            host: broker-2-${NAMESPACE}.${INGRESS_SUBDOMAIN}
        type: ${TYPE}
      plain: {}
      tls: {}
    config:
      offsets.topic.replication.factor: 3
      transaction.state.log.replication.factor: 3
      transaction.state.log.min.isr: 2
      log.message.format.version: '2.4'
    storage:
      type: ephemeral
  zookeeper:
    replicas: 3
    storage:
      type: ephemeral
  entityOperator:
    topicOperator: {}
    userOperator: {}
EOL

kubectl apply -f ${YAML_FILE} -n "${NAMESPACE}" || exit 1

KAFKA_RESOURCE="statefulset/${NAME}-kafka"
ZOOKEEPER_RESOURCE="statefulset/${NAME}-zookeeper"

count=0
until kubectl get ${KAFKA_RESOURCE} -n "${NAMESPACE}" 1> /dev/null 2> /dev/null; do
  if [[ ${count} -eq 12 ]]; then
    echo "Timed out waiting for ${KAFKA_RESOURCE} rollout to start"
    exit 1
  else
    count=$((count + 1))
  fi

  echo "Waiting for ${KAFKA_RESOURCE} rollout to start"
  sleep 30
done

count=0
until kubectl get ${ZOOKEEPER_RESOURCE} -n "${NAMESPACE}" 1> /dev/null 2> /dev/null; do
  if [[ ${count} -eq 12 ]]; then
    echo "Timed out waiting for ${ZOOKEEPER_RESOURCE} rollout to start"
    exit 1
  else
    count=$((count + 1))
  fi

  echo "Waiting for ${ZOOKEEPER_RESOURCE} rollout to start"
  sleep 30
done
