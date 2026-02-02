#!/bin/bash

source vars

echo "--- 11. Deploying NRI Plugin ---"

kubectl get nodes -o custom-columns=":metadata.name" --no-headers -l agentpool=gpunp | while read -r node; do
    echo "$node"
    kubectl debug "node/${node}" -it --image=busybox -- sh -c "cat <<EOF > /host/etc/containerd/conf.d/98-nri.toml
[plugins.\"io.containerd.nri.v1.nri\"]
  disable = false"
    kubectl debug "node/${node}" -it --image=busybox -- chroot /host systemctl restart containerd
done

kubectl apply -k https://github.com/containerd/nri/contrib/kustomize/ulimit-adjuster
kubectl -n kube-system patch daemonsets.apps nri-plugin-ulimit-adjuster -p '{"spec": {"template": {"spec": {"nodeSelector": {"agentpool": "gpunp"}}}}}'
