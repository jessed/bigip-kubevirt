## Installation order
1. Multus
  * multus/README.md

2. Kubevirt
  * kubevirt/README.md

3. cluster-network-addons
  * cni/CNA/README.md

4. Enable the 'macvtap' feature-gate
  * cni/CNA/README.md

5. Deploy CNA operator-cr
  * cni/CNA/README.md

6. Deploy macvtap config-maps
  * cni/macvtap/README.md

7. Deploy macvtap NetworkAttachmentDefinitions (net-attach-def)
  * cni/macvtap/README.md

At this point the cluster should be ready for VMI deployment.


## Upgrade process

## Newer versions of K8s may not be compatible with existing multus/kubevirt/cluster-network-addons behavior. This was the case with K8s v1.25, which required a different plug-in registration behavior, breaking KubeVirt v0.54.0. Should a similar issue be encountered I recommend upgrading all of these components (though Multus was not affected in the example above).

## Summary
1) Delete VMI(s)
2) Upgrade controller
3) Remove cluster-network-addons
4) Remove Kubevirt
5) Remove Multus
6) Install latest Multus
7) Install latest Kubevirt
8) Install latest Cluster-Network-Addons
9) Redeploy VMI(s)