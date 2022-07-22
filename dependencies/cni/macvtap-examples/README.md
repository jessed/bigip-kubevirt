# MACVTAP Components
#### [KubeVirt Macvtap Configuration](https://kubevirt.io/user-guide/virtual_machines/interfaces_and_networks/#macvtap)

## Summary of Steps
1. [Enable macvtap feature gate](https://kubevirt.io/user-guide/operations/activating_feature_gates/#how-to-activate-a-feature-gate)
2. Expose host interface
  - ConfigMap that defines the host, interface, mode, and capacity
  - See *iface.yaml files in this directory for examples
  - [Macvtap CNI](https://github.com/kubevirt/macvtap-cni#deployment)
3. Create a NetworkAttachmentDefinition (net-attach-def) that configures the macvtap network
  - See the *-net-attach-def.yaml files in this directory for examples
  - The net-attach-def annotation indicates which host interfaces to use
    - Must match the 'master' attribute in the CNI definition
4. VMIs can use the macvtap interface(s) by specifying the appropriate net-attach-def

