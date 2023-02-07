# BIG-IP in Kubernetes using KubeVirt and Multus

## Summary
This repository contains instructions, tools, and helper-scripts to perform the following:

* Install the Kubernetes components necessary to support multi-NIC BIG-IP traffic processing.
* Create a container image for BIG-IP using a VE qcow2 image
* Deploy a BIG-IP container into Kubernetes using cloud-init for the initial configuration
  * user-data for system configuration
  * optional: License assignment from registration key
  * network-data for interface, vlan, and address assignment


## Contents
* container/
  * The instructions for generating a container image from a BIG-IP qcow2 image.
  * Contains a helper-script for generating the image and pushing it to a repository

* dependencies/
  * Kubernetes dependencies to support a BIG-IP container with multiple NICs
  * .../multus
    * Instructions and helper-script for downloading and installing the [Multus CNI](https://github.com/k8snetworkplumbingwg/multus-cni)
  * .../kubevirt
    * Instructions and helper-script for downloading and installing [KubeVirt](https://github.com/kubevirt/kubevirt)
  * .../cni/CNA
    * Instructions and helper-script for downloading,installing, and configuring the KubeVirt [Cluster Network Addons Operator](https://github.com/kubevirt/cluster-network-addons-operator)
  * .../cni/macvtap
    * Instructions and helper-script for enabling and configuring macvtap interfaces using the KubeVirt Cluster Network Addons Operator

* bigip/
  * mk_pods.bash - Used to create pod yaml to deploy the bigip container into the K8s cluster. Also creates (or recreates) K8s secrets containing the cloud-init user-data and network-data to configure the BIG-IP instance
  * Includes template files used by the mk_pods.bash script to generate each component.


