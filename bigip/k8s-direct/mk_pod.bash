#! /bin/bash

registry="macpro:5000"
container="bigip-v1515"
version=3
containerName="bigip-v1515"

# Always or IfNotPresent
pullPolicy="Always"


configmapName="bigip-v1515"
cloudInit="cloud-init.bash"
userdataName="userdata"
userData=$(cat $cloudInit)
cidataName="cidata.txt"
#cidataB64Name="cidata64.txt"

# define config file variables
hostname="bigip-v1515.default.svc.cluster.local"
dnsServers="4.2.2.2 8.8.8.8"
ntpServers="tick.ucla.edu"
ntpTimezone="US/Pacific"
mgmtAddr=192.168.20.51
mgmtCidr=24
mgmtGtwy=192.168.20.1
dataVlanName1="external"
dataVlanTag1=4091
dataVlanAddr1=10.1.100.1
dataVlanCidr1=24
dataVlanMac1='40:00:00:00:00:01'
dataGtwy=10.10.100.254
dataVlanName2="internal"
dataVlanTag2=4092
dataVlanAddr2=10.2.100.1
dataVlanCidr2=24
dataVlanMac2='40:00:00:00:00:02'
adminPass="NotTodayNotTomorrow"
rootPass='NotTodayNotTomorrow'
proxyProtocol='https'
strictpasswords="disable"
pubKey="$(/usr/bin/base64 -w0 ssh_shared.pub)"
envFile="$(/usr/bin/base64 -w0 env.ltm)"
#proxyAddr='10.10.1.254'
#proxyPort='3128'
#regKey="OFJOJ-NTAGM-IYKYU-QIEFN-ZKKCYBH"

# Create config file for config-map creation
cat << END > cfgmap_bigip.yaml
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


# Create cloud-init with hardcoded values
sed -e '
s#pubKeyValue#'$pubKey'#
s#envFileValue#'$envFile'#
' $cloudInit > $cidataName 

# Create base64 encoded cloud-init
#cat $cidataName | base64 -w0 > ${cidataB64Name}

# Create new config-map with variables replace any existing entry
#kubectl replace -f cfgmap_bigip.yaml --force

# Create new userdata in secret and replace any existing entry
userdataSecret=$(kubectl get secret $userdataName 2>/dev/null)
if [[ $? == 0 ]]; then kubectl delete secret $userdataName; fi
if [[ $? == 0 ]]; then kubectl create secret generic $userdataName --from-file=userdata=$cidataName; fi


# Create new pod yaml
cat << END > pod.yaml
apiVersion: kubevirt.io/v1alpha3
kind: VirtualMachineInstance
metadata:
  name: $containerName
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
      autoattachGraphicsDevice: false
      disks:
      - name: containerdisk
        disk:
          bus: virtio
      - name: podinfo
        disk:
          bus: virtio
      - name: cloud-init
        disk:
          bus: virtio
      interfaces:
      - name: mgmt
        macvtap: {}
      - name: data1
        macvtap: {}
        macAddress: 40:00:00:00:00:02
      - name: data2
        macvtap: {}
        macAddress: 40:00:00:00:00:03
      - name: data3
        macvtap: {}
        macAddress: 40:00:00:00:00:01
  volumes:
  - name: containerdisk
    containerDisk:
      image: $registry/$container:$version
      imagePullPolicy: $pullPolicy
  - name: cloud-init
    cloudInitNoCloud:
      secretRef:
        name: $userdataName
  - name: podinfo
    downwardAPI:
      fields:
      - path: annotations
        fieldRef:
          fieldPath: metadata.annotations
  networks:
  - name: mgmt
    multus:
      networkName: mgmt
  - name: data1
    multus:
      networkName: data10
  - name: data2
    multus:
      networkName: data20
  - name: data3
    multus:
      networkName: data30
END


