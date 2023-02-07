The qcow2 to be containerized should be located in this directory and the Dockerfile should be 
updated to reference tha image.

The mk_container.bash script should be updated with the:
- image name
- image tag
- name or address of the registry to push to

Additional notes:
- The qcow2 should be suitable for use within KVM/Openshift
- The image can be from a default image, as well as a customized image.
  - Customized images should be modified without starting (mounting and editing the qcow2 directly), or built with a tool like the (F5 Image Generator)[https://github.com/f5devcentral/f5-bigip-image-generator].
