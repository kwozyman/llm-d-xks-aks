#!/bin/bash

source vars

echo "--- 9. Creating ${LLMD_NAMESPACE} namespace ---"
kubectl create namespace "${LLMD_NAMESPACE}"

rm -rf llm-d && git clone -b "${LLMD_VERSION}" --depth 1 https://github.com/llm-d/llm-d.git

echo "--- 10. Monitoring ---"
cd llm-d/docs/monitoring
./scripts/install-prometheus-grafana.sh --individual -n "${LLMD_NAMESPACE}"

# TODO: configmap ${LLMD_NAMESPACE}/llmd-grafana datasource.yaml to have isDefault=false

cd ../../../

