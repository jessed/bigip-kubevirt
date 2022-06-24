The qcow2 to be containerized should be located in this directory and the Dockerfile should be 
updated to reference tha image.

The mk_container.bash script should be updated with the:
- image name
- image tag
- name or address of the registry to push to

Additional notes:
- The qcow2 should be suitable for use within KVM/Openshift
- The image can be from a (shutdown) VM that you have already customized, as well as a base image with no customization.
