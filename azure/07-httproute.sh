#!/bin/bash

source vars

echo "--- 10. Deploying HTTPRoute ---"
rm -rf llm-d && git clone -b "${LLMD_VERSION}" --depth 1 https://github.com/llm-d/llm-d.git

cd llm-d/guides/inference-scheduling || exit
helmfile apply -n "${LLMD_NAMESPACE}"
kubectl apply -f httproute.yaml -n "${LLMD_NAMESPACE}"

kubectl create secret generic llm-d-hf-token --from-literal="HF_TOKEN=${HF_TOKEN}" --namespace "${LLMD_NAMESPACE}"
