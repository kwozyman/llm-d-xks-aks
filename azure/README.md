`llm-d` on Azure Kubernetes Service (AKS)
===

Prerequisites
---

* latest [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest) binary with `aks-preview` extension installed
* `kubectl` and `helm`

Installation
---

First, you need to edit the `vars` file which contains variables used by the scripts. In reality, the only environment variables that require change are `HF_TOKEN` (HuggingFace access token) and potentially `SSH_KEY_FILE` with a path to your RSA SSH public key.

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
