# Kubevirt Network Add-Ons Installation

### Use macvtap instead
[Kubevirt Interfaces](https://kubevirt.io/user-guide/virtual_machines/interfaces_and_networks/#macvtap)


## Install required components 
[Cluster Network Addons Operator Installation](https://github.com/kubevirt/cluster-network-addons-operator)
*Installation instructions at the bottom*

## Summary
kubectl apply -f https://github.com/kubevirt/cluster-network-addons-operator/releases/download/v0.77.0/namespace.yaml
kubectl apply -f https://github.com/kubevirt/cluster-network-addons-operator/releases/download/v0.77.0/network-addons-config.crd.yaml
kubectl apply -f https://github.com/kubevirt/cluster-network-addons-operator/releases/download/v0.77.0/operator.yaml

### Enable required add-ons and/or, including feature-gates
* Include affinity statements

## Additional Notes
### Using Multus in K8s
https://devopstales.github.io/home/multus/
- States that the interface used by the default network cannot be used by macvlan



### Kubevirt known issue with macvlan
- https://github.com/kubevirt/kubevirt/pull/2192
- https://github.com/kubevirt/kubevirt/pull/3489
- https://github.com/kubevirt/kubevirt/issues/5483


