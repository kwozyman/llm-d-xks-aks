#!/bin/bash
source vars

echo "--- 1. Creating Resource Group ---"
az group create --name "${RESOURCE_GROUP}" --location "${LOCATION}"

echo "--- 2. Creating AKS Cluster (System Pool) ---"
az aks create --resource-group "${RESOURCE_GROUP}" --name "${CLUSTER_NAME}" --node-count 1 --node-vm-size "Standard_D2s_v3" --ssh-key-value "${SSH_KEY_FILE}"

echo "--- 3. Adding GPU Node Pool (with Taint) ---"
# This is a critical step: --gpu-driver none lets the operator manage it.
az aks nodepool add \
    --resource-group "${RESOURCE_GROUP}" \
    --cluster-name "${CLUSTER_NAME}" \
    --name "gpunp" \
    --node-count 1 \
    --node-vm-size "${GPU_SKU}" \
    --gpu-driver none \
    --labels "sku=gpu"

echo "--- 4. Getting Cluster Credentials ---"
az aks get-credentials --resource-group "${RESOURCE_GROUP}" --name "${CLUSTER_NAME}" --overwrite-existing

