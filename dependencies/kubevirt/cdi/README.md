# Containerized Data Importer
## https://github.com/kubevirt/containerized-data-importer

This is necessary to use persistent volumes with kubevirt containers.
See [here](https://kubevirt.io/user-guide/virtual_machines/disks_and_volumes/#cloudinitconfigdrive) for more information.

kubectl create -f cdi-operator.yaml
kubectl create -f cdi-cr.yaml
