#!/bin/bash

source vars

echo "Deleting Azure Resource Group ${RESOURCE_GROUP} in the background..."
echo "This will take 10-15 minutes to complete."
az group delete --name ${RESOURCE_GROUP} --yes --no-wait

echo "Unregistering the ManagedGatewayAPIPreview feature..."
az feature unregister --namespace "Microsoft.ContainerService" --name "ManagedGatewayAPIPreview"

echo "Cleaning up local kubeconfig entry..."
kubectl config delete-cluster ${CLUSTER_NAME}
kubectl config delete-context ${CLUSTER_NAME}

echo "Cleaning up local Helm repositories..."
helm repo remove nvidia
helm repo remove llm-d-modelservice
helm repo remove llm-d-infra

echo "Cleanup initiated. The resource group ${RESOURCE_GROUP} is deleting in the background."

