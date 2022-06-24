#! /bin/bash

container=bigip-kv
version=base

userdataName="userdata"
configmapName="bigip-kv"

# define config file variables
hostname="bigip-v2.default.svc.cluster.local"
dnsServers="4.2.2.2 8.8.8.8"
ntpServers="tick.ucla.edu"
ntpTimezone="US/Pacific"
mgmtAddr=192.168.20.51
mgmtCidr=24
mgmtGtwy=192.168.20.1
dataVlanName1="external"
dataVlanTag1=4091
dataVlanAddr1=10.10.1.1
dataVlanCidr1=24
dataVlanMac1='40:00:00:00:00:01'
dataGtwy=10.10.1.254
dataVlanName2="internal"
dataVlanTag2=4092
dataVlanAddr2=10.20.1.1
dataVlanCidr2=24
dataVlanMac2='40:00:00:00:00:02'
adminPass="NotTodayNotTomorrow"
rootPass='NotTodayNotTomorrow'
proxyProtocol='https'
#proxyAddr='10.10.1.254'
#proxyPort='3128'
#regKey="OFJOJ-NTAGM-IYKYU-QIEFN-ZKKCYBH"
strictpasswords="disable"
pubKey="$(cat ssh_shared.pub)"
envFile="$(/usr/bin/base64 -w0 env.ltm)"

# Create config file for config-map creation
cat << END > cfgmap_bigip-kv.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: $configmapName
data:
  hostname: "$hostname"
  dnsServers: "$dnsServers"
  ntpServers: "$ntpServers"
  ntpTimezone: "$ntpTimezone"
  mgmtAddr: "$mgmtAddr"
  mgmtCidr: "$mgmtCidr"
  mgmtGtwy: "$mgmtGtwy"
  dataVlanName1: "$dataVlanName1"
  dataVlanTag1: "$dataVlanTag1"
  dataVlanAddr1: "$dataVlanAddr1"
  dataVlanCidr1: "$dataVlanCidr1"
  dataVlanMac1: "$dataVlanMac1"
  dataGtwy: "$dataGtwy"
  dataVlanName2: "$dataVlanName2"
  dataVlanTag2: "$dataVlanTag2"
  dataVlanAddr2: "$dataVlanAddr2"
  dataVlanCidr2: "$dataVlanCidr2"
  dataVlanMac2: "$dataVlanMac2"
  adminPass: "$adminPass"
  rootPass: "$rootPass"
  proxyProtocol: "$proxyProtocol"
  proxyAddr: "$proxyAddr"
  proxyPort: "$proxyPort"
  regKey: "$regKey"
  strictpasswords: "$strictpasswords"
  pubKey: "$pubKey"
  envFile: "$envFile"
END

# Create new config-map with variables replace any existing entry
kubectl replace -f cfgmap_bigip-kv.yaml --force

# Create new userdata in secret and replace any existing entry
userdataSecret=$(kubectl get secret $userdataName 2>/dev/null)
if [[ $? == 0 ]]; then kubectl delete secret $userdataName; fi
kubectl create secret generic $userdataName --from-file=userdata=cloud-init.bash


# Create new pod yaml
cat << END > pod.yaml
apiVersion: kubevirt.io/v1alpha3
kind: VirtualMachineInstance
metadata:
  name: bigip-kv
  annotations:
    k8s.v1.cni.cncf.io/networks: '[ {"name": "bigip-mgmt"} ]'
  labels:
    app: bigip
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
        memory: "4096Mi"
        cpu: "2"
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
      - name: networks
        disk:
          bus: virtio
      interfaces:
      - name: mgmt
        bridge: {}
      - name: data1
        bridge: {}
        macAddress: 40:00:00:00:00:02
      - name: data2
        bridge: {}
        macAddress: 40:00:00:00:00:03
      - name: data3
        bridge: {}
        macAddress: 40:00:00:00:00:01
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
  - name: networks
    configMap:
      name: $configmapName
  networks:
  - name: mgmt
    multus:
      networkName: bigip-mgmt
  - name: data1
    multus:
      networkName: bigip-data10
  - name: data2
    multus:
      networkName: bigip-data20
  - name: data3
    multus:
      networkName: bigip-data30
END


