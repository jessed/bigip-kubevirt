# AODS + F5 BIG-IP VE Deployment

## Background
Azure for Operators Distributed Services, AODS, is a new offering from Azure that extends the Azure Cloud Network to the customers location. Azure defines the specific hardware that the customer must purchase and deploy. Once the resources are deployed the customer registers it with Azure, allowing Azure completely control this environment. The intent is to leverage extend the Public Cloud to on-premesis, allowing the customer to retain direct control of the hardware that is processing customer data. While the environmnet is managed through Azure, the customer data never leaves the customer data-center(s).

AODS runs leverages Kubernetes for all CNF/VNF scheduling and execution. The Kubernetes aspect of AODS is entirely obscured from the customer, similar to how VELOS, r-Series, and BIG-IP Next use Kubernetes "under the hood" without exposing it to the customer for direct interaction. This "under the hood" K8s deployment is new to MSFT/Azure, and the entire system has been under development this year.

## Limitations and Incompatibilities with BIG-IP VE
Unfortunately, some of the architectural choices made by Azure for AODS cause problems with deploying BIG-IP into the environment. Here is a brief summary of those pain points:

1. Being based on K8s, AODS only supports the deployment of containers, not native virtual machines
    * This means that the BIG-IP QCOW2 image must be 'wrapped' by [Kubevirt](https://kubevirt.io/) and pushed to a registry as a container.
    * See the 'containers' subdirectory within this repository for a script to build and push a container using docker.
2. Azure has decided that AODS will only support 'headless' deployments, meaning that VMs will not have a default video device attached to the instance.
    * By default the VE image uses a graphical 'splash' screen presented by grub. This splash screen makes use of the framebuffer, which *requires* a video device attachment. If grub cannot access the framebuffer the boot process will stall; there is no timeout period, it will block the boot process indefinitely.
    * For this reason it is necessary to create a customer QCOW2 image that removes the grub splash screen.
    * This decision is intended to save memory because the virtual video device consumes 16MB of memory. This equates to 1GB of memory for every 64 VMs deployed into AODS.
      * NOTE: This is a deviation from normal Azure VM deployments, which do receive a default video device (though it is unused).
3. AODS does not support K8s config-maps, nor any other method of providing configuration data to the instance at boot-time other than the cloud-init script itself.
    * As suggested above, this means that the cloud-init script passed to the VM must have all variables hard-coded.
    * This limitation is due to the azure CLI lacking support for config-maps, not due to any restriction at the Kubernetes layer. 
        * This decision is probably the result of wanting to abstract K8s management from the customer. 
    * AODS is currently working on a method of making network data available via the a mountable volume.
        * The format *should* match Cloud-Init's [Network Config Version 2](https://cloudinit.readthedocs.io/en/latest/topics/network-config-format-v2.html#network-config-v2) format, which is basically netplan format.
        * The difficulty of extracting BIG-IP configuration information from this format remains to be seen.
    * It *may* be possible to leverage the [f5-bigip-runtime-init](https://github.com/F5Networks/f5-bigip-runtime-init#inline-big-ip-runtime-config) to retrieve the configuration data at first-boot. This possiblity has not yet been investigated.
        * The latest version of the f5-bigip-runtime-init does not appear to require a custom image (unlike previous versions), making this approach more attractive.
4. AODS mandates the use of Mellanox ConnectX-6 network cards, and from those SRIOV virtual-functions are exposed to the VMs using the [Multus CNI](https://github.com/k8snetworkplumbingwg/multus-cni).
    * Purely virtual interfaces (i.e. virtio) are **not** supported at all; all interfaces are ConnectX-6 virtual-functions.
      * The K8s pod network is **not** connected to the VM.
    * BIG-IP VE does not currently have native suport for the ConnectX-6 NIC
      * The ConnectX-6 is backward compatible with the ConnectX-5 driver, which TMM supports (but not CentOS)
      * A /config/tmm_init.tcl file can be used to force TMM to use the ConnectX-5 driver for the ConnectX-6 device ID
      * It *should* be possible to map the ConnectX-6 device to the ConnectX-5 driver in the OS (not just TMM), but confirming this won't be possible until VMs can actually be deployed to AODS.
        * Assuming it is possible, the cloud-init should be capable of making the change at first-boot


## Files
* mk_instance.bash
  * Wrapper script for AODS VM instantiation
* v_aods.txt
  * AODS environment variables
* v_bigip01.txt
  * BIG-IP configuration variables
  * Should be copied to a new file for each VM deployed
* v_cloud-init.template
  * Cloud-init script template

## Operation
The mk_instance.bash wrapper script sources the v_aods.txt and v_bigip01.txt files to create the variables required for the instance deployment. The *v_cloud-init.template* file contains the actual cloud-init that will be executed on first boot by the cloud-init subsystem on the VE. The cloud-init script is processed by the *mk_instance.bash* wrapper script to insert all necessary variables into the final cloud-init script. This effectively hardcodes them for each instance, but that is required due to AODS limitations (see above).

The final output is a file called *az_command.bash*, which contains the command that would be executed (typically by calling the file with bash like a shell script). The actual 'az networkfunction virtualmachine create' command isn't very complex, but embedding the cloud-init into the 'virtual-machine-parameters' argument does make it very large and ungainly to work with directly. There is no technical reason that the *mk_instance.bash* script could not execute the 'az networkfunction virtualmachine create' command directly; sending the command to a file for manual execution just allows for simpler debugging. The script will be updated to call the az command directly at a later point.

