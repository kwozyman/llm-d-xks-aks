#!/bin/bash

source vars

helm plugin install https://github.com/databus23/helm-diff
echo "--- 7. Installing gateway provider dependencies ---"
curl -L "https://raw.githubusercontent.com/llm-d/llm-d/refs/tags/${LLMD_VERSION}/guides/prereq/gateway-provider/install-gateway-provider-dependencies.sh" | /bin/bash
echo "--- 8. Installing Istio ---"
curl -L "https://raw.githubusercontent.com/llm-d/llm-d/refs/tags/${LLMD_VERSION}/guides/prereq/gateway-provider/istio.helmfile.yaml" | helmfile apply -f -
echo "--- Verify gateway installation ---"
kubectl api-resources --api-group=inference.networking.k8s.io
kubectl api-resources --api-group=inference.networking.x-k8s.io

