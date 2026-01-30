#!/bin/bash
source vars

echo "--- 1. Creating Resource Group ---"
az group create --name "${RESOURCE_GROUP}" --location "${LOCATION}"

echo "--- 2. Creating AKS Cluster (System Pool) ---"
az aks create --resource-group "${RESOURCE_GROUP}" --name "${CLUSTER_NAME}" --node-count 1 --node-vm-size "${CONTROL_SKU}" --ssh-key-value "${SSH_KEY_FILE}"

echo "--- 3. Adding GPU Node Pool (with Taint) ---"
az aks nodepool add \
    --resource-group "${RESOURCE_GROUP}" \
    --cluster-name "${CLUSTER_NAME}" \
    --name "gpunp" \
    --node-count "${NODE_COUNT}" \
    --node-vm-size "${GPU_SKU}" \
    --gpu-driver none \
    --labels "sku=gpu"

echo "--- 3. Getting Cluster Credentials ---"
az aks get-credentials --resource-group "${RESOURCE_GROUP}" --name "${CLUSTER_NAME}" --overwrite-existing

