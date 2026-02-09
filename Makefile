RESOURCE_GROUP ?= "cgament-llmd-rg-1"
CLUSTER_NAME ?= "cgament-llmd-cluster-1"
LOCATION ?= "eastus"
CONTROL_SKU ?= "Standard_D5_v2"
GPU_SKU ?= "Standard_NC24ads_A100_v4"
NODE_COUNT ?= "1"
SSH_KEY_FILE ?= "${HOME}/.ssh/azure.pub"
GPU_OPERATOR_VERSION ?= "v25.10.0"
NODEPOOL_NAME ?= "gpunp"
GPU_NODE_LABEL ?= "sku=gpu"
NRI_NAMESPACE ?= "kube-system"

check-deps:
	@which az
	@az extension list | grep -i preview
	@which kubectl
	@which helm
	@which helmfile


clean: cluster-clean
cluster: cluster-create cluster-credentials
deploy: deploy-gpuoperator deploy-nriconfig

cluster-clean:
	@echo "Deleting Azure Resource Group ${RESOURCE_GROUP} in the background..."
	@echo "This will take 10-15 minutes to complete."
	az group delete --name "${RESOURCE_GROUP}" --yes --no-wait
	@echo "Unregistering the ManagedGatewayAPIPreview feature..."
	az feature unregister --namespace "Microsoft.ContainerService" --name "ManagedGatewayAPIPreview"
	@echo "Cleaning up local kubeconfig entry..."
	kubectl config delete-cluster "${CLUSTER_NAME}"
	kubectl config delete-context "${CLUSTER_NAME}"
	@echo "Cleaning up local Helm repositories..."
	helm repo remove nvidia
	@echo "Cleanup initiated. The resource group ${RESOURCE_GROUP} is deleting in the background."

cluster-create:
	@echo "Creating Resource Group"
	az group create --name "${RESOURCE_GROUP}" --location "${LOCATION}"
	@echo "Creating AKS Cluster (control plane)"
	az aks create --resource-group "${RESOURCE_GROUP}" --name "${CLUSTER_NAME}" --node-count "${NODE_COUNT}" \
		--node-vm-size "${CONTROL_SKU}" --ssh-key-value "${SSH_KEY_FILE}"
	@echo "Adding GPU Node Pool"
	az aks nodepool add --resource-group "${RESOURCE_GROUP}" --cluster-name "${CLUSTER_NAME}" \
		--name "${NODEPOOL_NAME}" --node-count "${NODE_COUNT}" --node-vm-size "${GPU_SKU}" \
		--gpu-driver none --labels "${GPU_NODE_LABEL}"

cluster-credentials:
	@echo "Getting Cluster Credentials"
	az aks get-credentials --resource-group "${RESOURCE_GROUP}" --name "${CLUSTER_NAME}" --overwrite-existing

deploy-gpuoperator:
	@echo "Deploying Nvidia GPU Operator"
	helm repo add nvidia https://helm.ngc.nvidia.com/nvidia
	helm repo update
	helm install --wait -n gpu-operator --create-namespace \
		gpu-operator nvidia/gpu-operator \
		--version "${GPU_OPERATOR_VERSION}" \
		--set "driver.rdma.enabled=true"

deploy-nriconfig:
	@echo "Deploying NRI plugin"
	helm upgrade --install nri-setup ../nri-config/ --namespace "${NRI_NAMESPACE}" --create-namespace
