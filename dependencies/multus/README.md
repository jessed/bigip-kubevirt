# Multus installation

1. Clone [Multus repository](https://github.com/k8snetworkplumbingwg/multus-cni.git)
   - The 'get-latest-multus.bash script should clone the repo and create a symlink to the appropriate file.
2. Install with: kubectl apply -f deployments/multus-daemonset-thick.yml


