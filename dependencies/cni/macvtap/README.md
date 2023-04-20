# MACVTAP Components
#### [KubeVirt Macvtap Configuration](https://kubevirt.io/user-guide/virtual_machines/interfaces_and_networks/#macvtap)

## Summary
1. Expose host interface
  - ConfigMap that defines the host, interface, mode, and capacity
  - See iface*.yaml files in this directory for examples
  - [Macvtap CNI](https://github.com/kubevirt/macvtap-cni#deployment)

2. Create a NetworkAttachmentDefinition (net-attach-def) that configures the macvtap network
  - See the *-net-attach-def.yaml files in this directory for examples
  - The annotation indicates which host interface to use
    - Must match the 'master' attribute in the CNI definition

3. VMIs can use the macvtap interface(s) by specifying the appropriate net-attach-def


## Example order of operations
### First interface (mgmt)
kubectl create -f iface-enp11s0-configmap.yaml
kubectl create -f mgmt-net-attach-def.yaml

### Additional interfaces (data-plane)
kubectl create -f iface-enp12s0-configmap.yaml
kubectl create -f data10-net-attach-def.yaml
kubectl create -f data20-net-attach-def.yaml
kubectl create -f data30-net-attach-def.yaml

