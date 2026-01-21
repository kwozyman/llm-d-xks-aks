`llm-d` on Azure Kubernetes Service (AKS)
===

Prerequisites
---

* latest [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest) binary with `aks-preview` extension installed
* `kubectl` and `helm`

Installation
---

The actual commands used for installation are provided as numbered scripts in this repository. They should be referenced in conjunction to this documentation.

First, you need to edit the `vars` file which contains variables used by the scripts. In reality, the only environment variables that require change are `HF_TOKEN` (HuggingFace access token) and potentially `SSH_KEY_FILE` with a path to your RSA SSH public key.

The variables that can be defined here are:

  * `RESOURCE_GROUP` -- name of the Azure resource group
  * `CLUSTER_NAME` -- AKS (Azure Kubernetes Service) cluster name
  * `LOCATION` -- Azure region
  * `GPU_SKU` -- What VM type to use for worker nodes. The flavors that are known to work are: `Standard_NC24ads_A100_v4`, `Standard_ND96asr_v4`, `Standard_ND96amsr_A100_v4`, `Standard_ND96isr_H100_v5` or `Standard_ND96isr_H200_v5`
  * `HF_TOKEN` -- HugginFace token -- this should be kept secret!
  * `SSH_KEY_FILE` -- public key file to be used for access to the cluster nodes
  * `GPU_OPERATOR_VERSION` -- version of GPU Operator to deploy
  * `LLMD_VERSION` -- Version of LLMD to deploy
  * `LLMD_NAMESPACE` -- in what namespace to deploy llmd

`01-cluster-create.sh`

This first script focuses on the infrastructure provisioning phase. It sets up the foundational Azure resources required to host a GPU-accelerated Kubernetes environment. The important bits to note here is the difference between control plane virtual machines (a small `Standard_D2s_v3` is used) and worker virtual machines. We are adding one node of the type `${GPU_SKU}` (defaults to `Standard_NC6s_v3`).

An important detail here is the `--gpu-driver none` argument for the worker nodes. This allows the user to install NVidia driver by using GPU Operator at a later time.

`02-gpuoperator.sh`

The second script handles the GPU drivers layer. Since the node pool was initialized with `--gpu-driver none` in the previous step, this script installs GPU Operator that in turn deploys needed NVidia drivers. This is handled via `helm`:

```
helm install --wait -n gpu-operator --create-namespace \
    gpu-operator nvidia/gpu-operator \
    --version "${GPU_OPERATOR_VERSION}" \
    --set "driver.rdma.enabled=true"
```

Of note is the `--set "driver.rdma.enabled=true"` argument, which enables RDMA. This is harmless even if using a single node. The compilation and deplyoment of GPU Operator will take several minutes. It is best to watch the pods using `kubectl -n gpu-operator get pod` until all pods are in state "Running".


`03-istio.sh`

This script prepares the cluster to handle specialized AI inference traffic. It installs the required Custom Resource Definitions (CRDs) and the service mesh (Istio) that will manage the lifecycle of LLM requests. This is done by using official llm-d scripts (hence the downloading of llm-d code repository) and Istio is used to ensure traffic is distributed efficiently across GPU nodes. Succesful installation should display something akin to:

```
--- Verify gateway installation ---
NAME             SHORTNAMES   APIVERSION                       NAMESPACED   KIND
inferencepools   infpool      inference.networking.k8s.io/v1   true         InferencePool
NAME                  SHORTNAMES   APIVERSION                               NAMESPACED   KIND
inferenceobjectives                inference.networking.x-k8s.io/v1alpha2   true         InferenceObjective
inferencepools        xinfpool     inference.networking.x-k8s.io/v1alpha2   true         InferencePool
```

`04-monitoring.sh`

This script deploys the monitoring stack for llm-d. It's using the upstream `install-prometheus-grafana.sh`. However, *there is a manual step required*. While the script is running, you should edit configmap `${LLMD_NAMESPACE}/llmd-grafana` to specify llmd-grafana is *not* the default data source:

```
$ source vars && kubectl -n "${LLMD_NAMESPACE}" edit configmaps llmd-grafana
# now edit "data.datasources.yaml.datasources[0].isDefault" and set it to "false"

$ kubectl -n "${LLMD_NAMESPACE}" get configmaps llmd-grafana -o json | jq '.data["datasources.yaml"]' | yq | yq -o json | jq '.datasources[0].isDefault'
false
```

`05-netop.sh`

Network operator installation. This phase installs the NVIDIA Network Operator and configures the cluster policies required for high-speed, low-latency communication between GPU nodes. This is critical for Distributed Training and Multi-Node Inference, where data must be synchronized across the network rapidly, but does not impede single node inference, so it can be safely deployed even for a single node installation. The network operator deployment can take a long time, so please be patient. To check, wait until all `network-operator` pods are in state "Running":

```
$ kubectl -n network-operator get pod

```

`06-nri.sh`

By default, Azure Kubernetes Service sets a maximum locked memory limit of 64K per container, which is insufficient for vLLM's NIXL connector. To address this limitation, Node Resource Interface must be enabled on all GPU nodes. This script *must* run only after GPU Operator has completely finished deploying.

`07-httproute.sh`

This phase deploys the high-level routing rules that direct traffic to your models and configures the authentication required to download model weights from external registries like Hugging Face.

`08-llmd.sh`

This phase moves beyond infrastructure to the actual AI application layer, where the LLM-D scheduler and model servers (vLLM) are instantiated.

Validation
---

After deplyoment, there are a couple of tests that can be used as validation:

1. Check GPU detection

```
kubectl describe nodes -l sku=gpu | grep -E "nvidia.com/gpu|rdma/ib"
```

Output should contain something like `nvidia.com/gpu: [number]` and `rmda/ib: [number]`.

2. Check GPU operator pods

```
kubectl get pods -n gpu-operator
kubectl get pods -n network-operator
```

All of the pods should be in state "Running".

3. Verify gateway ip

```
export GATEWAY_IP=$(kubectl get gateway -n "${LLMD_NAMESPACE}" -o jsonpath='{.status.addresses[0].value}')
echo "Gateway IP: ${GATEWAY_IP}"
```

4. Verify llmd pods

```
kubectl get pods -n "${LLMD_NAMESPACE}" -w
```

All the pods should be in "Running" state.

