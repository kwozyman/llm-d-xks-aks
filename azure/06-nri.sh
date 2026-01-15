#!/bin/bash

source vars

echo "--- 11. Deploying NRI Plugin ---"

kubectl get nodes -o custom-columns=":metadata.name" --no-headers -l agentpool=gpunp | while read -r node; do
    echo "$node"
    kubectl debug "node/${node}" -it --image=busybox -- sh -c "cat <<EOF > /host/etc/containerd/conf.d/98-nri.toml
[\"plugins.io.containerd.nri.v1.nri\"]
  disable = false"
done

kubectl apply -k https://github.com/containerd/nri/contrib/kustomize/ulimit-adjuster

