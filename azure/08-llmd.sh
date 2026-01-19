#!/bin/bash

source vars

echo "--- 11. HF token ---"
kubectl create secret generic hf-token \
    --from-literal="HF_TOKEN=${HF_TOKEN}" \
    --namespace "${LLMD_NAMESPACE}" \
    --dry-run=client -o yaml | kubectl apply -f -

echo "--- 12. llm-d install"
rm -rf llm-d && git clone -b "${LLMD_VERSION}" --depth 1 https://github.com/llm-d/llm-d.git
cd llm-d/guides/inference-scheduling
helmfile apply -n "${LLMD_NAMESPACE}"
cd ../../../

