# Kubevirt Network Add-Ons Installation


## Summary
1. Install cluster-network-addons
  [Cluster Network Addons Operator Installation](https://github.com/kubevirt/cluster-network-addons-operator)
  * See CNA/ directory
  * Order:
    - namespace.yaml
    - network-addons-config.crd.yaml
    - operator.yaml

2. Enable macvtap "feature gate"
  * See CNA/exmples/enable-featuregates.yaml

3. Deploy **customized** operator-cr
  * See CNA/examples/operator-cr.yaml

4. Deploy interface config-maps
  * See macvtap/README.md

5. Deploy NetworkAttachmentDefinitions (net-attach-def)
  * See macvtap/README.md

