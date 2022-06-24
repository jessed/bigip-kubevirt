#! /bin/bash

container=kvtest
version=3

userdataName="ubuntu-userdata"
configmapName="kvtest"

# define config-map variables
hostname="kvtest"

# Create config-map yaml file
cat << END > ${configmapName}.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: $configmapName
data:
  hostname: "$hostname"
END

# Create net config-map with variables
kubectl replace -f ${configmapName}.yaml --force

# Create new userdata in secret and replace any existing entry
userdataSecret=$(kubectl get secret $userdataName 2>/dev/null)
if [[ $? == 0 ]]; then kubectl delete secret $userdataName; fi
kubectl create secret generic $userdataName --from-file=userdata=cloud-init.bash


# create new pod yaml
cat << END > pod.yaml
apiVersion: kubevirt.io/v1alpha3
kind: VirtualMachineInstance
metadata:
  name: kvtest
spec:
  nodeSelector:
    kubernetes.io/hostname: macpro
  domain:
    cpu:
      model: IvyBridge-IBRS
    machine:
      type: q35
    resources:
      requests:
        memory: "2048Mi"
        cpu: "1"
    devices:
      disks:
      - name: containerdisk
        disk:
          bus: virtio
      - name: cloudinitdisk
        disk:
          bus: virtio
      - name: podinfo
        disk:
          bus: virtio
      - name: civars
        disk:
          bus: virtio
      interfaces:
      - name: mgmt
        macvtap: {}
        macAddress: 40:83:83:83:83:01
      - name: data
        macvtap: {}
        macAddress: 40:83:83:83:83:02
      - name: pod
        bridge: {}
  networks:
  - name: mgmt
    multus:
      networkName: macvtap-macpro
  - name: data
    multus:
      networkName: macvtap-macpro
  - name: pod
    pod: {}
  volumes:
  - name: containerdisk
    containerDisk:
      image: k83:5000/$container:$version
  - name: cloudinitdisk
    cloudInitConfigDrive:
      secretRef:
        name: $userdataName
  - name: podinfo
    downwardAPI:
      fields:
      - path: annotations
        fieldRef:
          fieldPath: metadata.annotations
  - name: civars
    configMap:
      name: $configmapName
END
