`llm-d` on Azure Kubernetes Service (AKS)
===

Prerequisites
---

* latest [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest) binary with `aks-preview` extension installed
* `kubectl` and `helm`

Installation
---

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

This script creates a resource group and a AKS cluster (names can be changed via the appropriate environment variables). In step 3 a new node pool called "gpunp" is created and the cluster is extended with 2 GPU nodes.

`02-gpuoperator.sh`

Using `helm`, this script installs the NVidia GPU Operator with RDMA enabled (`driver.rdma.enabled=true` parameter).

`03-istio.sh`

Istio is installed as the gateway provider.

`05-netop.sh`

Network operator installation.

`06-nri.sh`

By default, Azure Kubernetes Service sets a maximum locked memory limit of 64K per container, which is insufficient for vLLM's NIXL connector. To address this limitation, Node Resource Interface must be enabled on all GPU nodes. This script *must* run only after GPU Operator has completely finished deploying.


