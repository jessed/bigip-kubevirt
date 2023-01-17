        #cloud-config
        
        write_files:
          - path: /shared/cloud_init.bash
            permissions: 0755
            content: |
              #! /bin/bash
        
              # 1 = debugging enabled, 0 = debugging disabled
              DEBUG=1
              # source wait_bigip_ready* functions
              source /usr/lib/bigstart/bigip-ready-functions
        
              ### Static variables
              podInfo="/run/kv-annotations"
              annotations="$podInfo/annotations"
        
              # config-map containing ltm config variables
              declare -A config
              declare -A mac_map
              declare -A interfaces
              ltmInfo="/run/kv-ltm"
              logDir="/shared/logdisk"
        
              # Hardcode config elements to work-around the lack of config-maps in AODS
              config[hostname]="bigip-v1515.default.svc.cluster.local"
              config[dnsServers]="4.2.2.2 8.8.8.8"
              config[ntpServers]="tick.ucla.edu"
              config[ntpTimezone]="US/Pacific"
              config[mgmtAddr]=192.168.20.51
              config[mgmtCidr]=24
              config[mgmtGtwy]=192.168.20.1
              config[dataVlanName1]="external"
              config[dataVlanTag1]=4091
              config[dataVlanAddr1]=10.1.100.1
              config[dataVlanCidr1]=24
              #config[dataVlanMac1]='40:00:00:00:00:01'
              config[dataGtwy]=10.10.100.254
              config[dataVlanName2]="internal"
              config[dataVlanTag2]=4092
              config[dataVlanAddr2]=10.2.100.1
              config[dataVlanCidr2]=24
              #config[dataVlanMac2]='40:00:00:00:00:02'
              config[adminPass]="NotTodayNotTomorrow"
              config[rootPass]='NotTodayNotTomorrow'
              config[proxyProtocol]='https'
              config[strictpasswords]="disable"
              config[pubKey]="pubKeyValue"
              config[envFile]="envFileValue"
              #proxyAddr='10.10.1.254'
              #proxyPort='3128'
              #regKey="OFJOJ-NTAGM-IYKYU-QIEFN-ZKKCYBH"
        
        
              # cloud-init output location for review/troubleshooting
              ciDir="/shared/cloud_init"
        
              ###
              ### Functions
              ###
        
              # Create a logging function that attempts to write the log output to the log disk
              function log() {
                if [[ -n $LOGFILE ]]; then
                  echo "$1" | tee -a $LOGFILE
                else
                  echo "$1"
                fi
              }
        
              # Unmount pod annotations and config-map disks
              # Mount disks with pod annotations and config-map with ltm config
              function mount_podinfo() {
                # Create and mount pod annotations and bigip_v1515 config-map
                if [[ ! -d $podInfo ]]; then mkdir $podInfo; fi
                mount /dev/vdc $podInfo #2>/dev/null
                if [[ $? != 0 ]]; then
                  log "$(date +%T) Attempt to mount /dev/vdc to $podInfo failed"
                fi
        
                if [[ ! -d $ltmInfo ]]; then mkdir -p $ltmInfo; fi
                mount /dev/vdd $ltmInfo #2>/dev/null
                if [[ $? != 0 ]]; then
                  log "$(date +%T) Attempt to mount /dev/vdd to $ltmInfo failed"
                fi
              }

              # Mount a disk for logging
              function mount_logdisk() {
                if [[ ! -d $logDir ]]; then mkdir $logDir; fi
                mount /dev/vdd $logDir
                if [[ $? != 0 ]]; then
                  log "$(date +%T) Failed to mount logging disk with 'mount /dev/vdd $logDir'"
                else
                  export LOGFILE="$logDir/$(date +%Y-%m-%d-%H-%M).log"
                fi
              }

              function unmount_podinfo() {
                log "$(date +%T) Unmounting $podInfo and $ltmInfo"
                # Unmount and delete podinfo directory
                umount $podInfo; rmdir $podInfo
                umount $ltmInfo; rmdir $ltmInfo
                log "$(date +%T) $podInfo and $ltmInfo now unmounted"
              }
        
              # Craete cloud-init info location
              function create_ci_dir() {
                # Create cloud_init dir, link to /root/, and output variable values
                if [[ ! -d $ciDir ]]; then
                  mkdir /shared/cloud_init
                  ln -s /shared/cloud_init /root/cloud_init
                else
                  rm -rf $ciDir/*
                fi
        
                # copy this script to cloud_init location for troubleshooting
                cp $0 $ciDir/cloud_init.bash && chmod 755 $ciDir/cloud_init.bash
              }
        
              # Get pod address
              function get_pod_addr() {
                if [[ -f $annotations ]]; then
                  podAddr=$(cat $annotations | grep podIP | cut -d= -f2 | uniq | sed 's/"//g')
                  log "$(date +%T) Found pod address: $podAddr"
                else
                  log "$(date +%T) WARNING: $annotations not found, cannot determine Pod network address"
                fi
              }
              
              # Get BIG-IP configuration elements
              function get_ltm_cfg() {
                if [[ -d $ltmInfo ]]; then
                  for k in $(ls -1 $ltmInfo); do
                    v=$(cat $ltmInfo/$k)
                    config[$k]=$v
                  done
        
                  log "$(date +%T) Successfully sourced $ltmInfo"
                  test -f /shared/config-map.txt && rm /shared/config-map.txt
                  for k in ${!config[*]}; do
                    printf "%20s -> %20s\n" $k ${config[$k]} >> /shared/config-map.txt
                  done
                  log "$(date +%T) config-map contents written to /shared/config-map.txt"
                else
                  log "$(date +%T) ERROR: $ltmInfo not found, CLOUD-INIT VARIABLES UNAVAILABLE"
                fi
              }
        
        
              # Configure system global settings
              function update_global() {
                # Disable DHCP if a management-ip was provided in config-map
                if [[ -n ${config[mgmtAddr]} ]]; then
                  log "$(date +%T) Found mgmtAddr, disabling management DHCP"
                  tmsh modify sys global-settings mgmt-dhcp disabled
                fi
        
                log "$(date +%T) Setting hostname to '${config[hostname]}'"
                tmsh modify sys global-settings hostname ${config[hostname]}
                log "$(date +%T) Setting DNS servers to ${config[dnsServers]}"
                tmsh modify sys dns name-servers replace-all-with { ${config[dnsServers]} }
                log "$(date +%T) Setting timezone to ${config[ntpTimezone]} and NTP servers to ${config[ntpServers]}"
                tmsh modify sys ntp servers replace-all-with { ${config[ntpServers]} } timezone ${config[ntpTimezone]}
                log "$(date +%T) Updating scp whitelist to include /shared"
                echo "/shared" >> /config/ssh/scp.whitelist
                tmsh restart sys service sshd
        
                if [[ ${config[strictpasswords]} == "disable" ]]; then
                  log "$(date +%T) Disabling strict password policy"
                  tmsh modify sys db users.strictpasswords value ${config[strictpasswords]}
                fi
              }
        
              # Change admin password 
              function update_credentials() {
                # admin user
                if [[ -n ${config[adminPass]} ]]; then
                  log "$(date +%T) Updating admin password"
                  tmsh modify auth user admin shell bash password ${config[adminPass]}
                fi
        
                # root user
                if [[ -n ${config[rootPass]} ]]; then
                  log "$(date +%T) Updating root password"
                  log ${config[rootPass]} | awk '{printf "%s\n%s\n", $1, $1}' | tmsh modify auth password root
                fi
        
              }
        
              # Add $sshKey to admin and root
              function inject_pubkey() {
                if [[ -n ${config[pubKey]} ]]; then
                  pubKey=$(echo ${config[pubKey]} | base64 -d)
                  log "$(date +%T) Found ssh public key; adding to authorized_keys"
                  log "$(date +%T) Key: $pubKey"
                  echo "${config[pubKey]}" | base64 -d >> /var/ssh/root/authorized_keys
                  echo "${config[pubKey]}" | base64 -d >> /home/admin/.ssh/authorized_keys
                else
                  log "$(date +%T) Skipping SSH public key insertion, config[pubKey] not defined"
                fi
              }
        
              # Assign management-ip only if a mgmtAddr is found in the config-map
              function assign_mgmt_addr() {
                # Assign management addr
                if [[ -n ${config[mgmtAddr]} ]]; then
                  log "$(date +%T) Deleting default/dhcp management-ip"
                  tmsh delete sys management-ip all
                  log "$(date +%T) Setting management-ip to ${config[mgmtAddr]}"
                  tmsh create sys management-ip ${config[mgmtAddr]}/${config[mgmtCidr]}
                fi
                if [[ -n ${config[mgmtGtwy]} ]]; then
                  log "$(date +%T) Creating management default-route"
                  tmsh create sys management-route default gateway ${config[mgmtGtwy]}
                fi
              }
              
              # create vlans based on mac-addresses provided in the config-map
              function create_dataplane_by_mac() {
                # Find all nics
                nics=$(tmsh show net interface | awk '/^1/ { printf("%s ", $1) }')
        
                log "$(date +%T) Beginning interface identification for interfaces: $nics"
                # First wait for interfaces to be available in case TMM isn't done initializing
                for n in $nics; do
                  # Wait up to 120 seconds for the mac addresses to become populated
                  for (( count=0; $count < 120; count++)); do
                    mac=$(tmsh show net interface $n all-properties | awk '/^1/ { print tolower($3) }')
                    if [[ -n $mac && ! $mac =~ "none"  ]]; then
                      log "$(date +%T) Found mac address for $n ($mac), adding to interface list"
                      interfaces[${n#0}]=${mac#0}
                      break
                    else
                      sleep 1
                    fi
                  done
                  if [[ -z ${interfaces[${n#0}]} ]]; then
                    log "$(date +%T) ERROR: Failed to find mac-address for interface $n"
                  fi
                done
        
                log "$(date +%T) Interface identification complete"
                test $DEBUG && {
                  tmsh show net interface all-properties
                  log "$(date +%T) Interfaces mapped:"
                  for i in ${!interfaces[@]}; do
                    echo "$i -> ${interfaces[$i]}"
                  done
                }
        
        
                # Associate interface with config-map entries based on index id
                dataVlanMac="dataVlanMac*"
                for n in ${!config[@]}; do
                  if [[ ! $n =~ $dataVlanMac ]]; then continue; fi
                  # get the index id
                  id=${n: -1}
                  vlan_mac=$(echo ${config[$n]} | tr -d ':.' | tr [:upper:] [:lower:])
                  test $DEBUG && log "$(date +%T) Processing dataVlanMac: $n (vlan_mac: $vlan_mac)"
        
                  # Create the mac-address to index mapping
                  for i in ${!interfaces[@]}; do
                    imac=$(echo ${interfaces[$i]} | tr -d ':.' | tr [:upper:] [:lower:])
                    test $DEBUG && log "$(date +%T) interface: $i, mac: $imac"
                    if [[ ${imac#0} =~ ${vlan_mac#0} ]]; then
                      test $DEBUG && log "$(date +%T) Associating interface $i (mac: $imac) with index $id (${config[dataVlanMac${id}]})"
                      mac_map[${imac}]=${id}
                      break
                    fi
                  done
                done
        
                # Now create the configuration using the interface and the mapped index
                for n in ${!interfaces[@]}; do
                  iface=$n
                  mac=$(echo ${interfaces[$n]} | tr -d ':.' | tr [:upper:] [:lower:])
        
                  # Make sure this mac exists in the mac_map array
                  if [[ ${mac_map[$mac]} == "" ]]; then continue; fi
                  id=${mac_map[$mac]}
                  vlanAddr=${config[dataVlanAddr${id}]}
                  vlanCidr=${config[dataVlanCidr${id}]}
                  vlanMac=${config[dataVlanMac${id}]}
        
                  # Define vlan name if none provided
                  if [[ -n ${config[dataVlanName${id}]} ]]; then
                    vlanName=${config[dataVlanName${id}]}
                  else
                    vlanName=$(printf "vlan%03d" $id)
                  fi
        
                  # Define vlan name if none provided
                  if [[ -n ${config[dataVlanTag${id}]} ]]; then
                    vlanTag=${config[dataVlanTag${id}]}
                  else
                    vlanTag=$((4000 + $id))
                  fi
        
        
                  # Create the vlan
                  log "$(date +%T) Creating vlan $vlanName (tag: $vlanTag) with interface '$iface'"
                  test $DEBUG && log "tmsh create net vlan $vlanName tag $vlanTag interfaces add { $iface }"
                  tmsh create net vlan $vlanName tag $vlanTag interfaces add { $iface }
        
                  # Create the self-ip for that vlan
                  log "$(date +%T) Create self-IP '$vlanAddr' and assigning to vlan '$vlanName'"
                  test $DEBUG && log "tmsh create net self ${vlanAddr}/${vlanCidr} vlan $vlanName"
                  tmsh create net self ${vlanAddr}/${vlanCidr} vlan $vlanName
                done
              }
        
              # create vlans based on interface order
              function create_dataplane_by_order() {
                nics=$(tmsh show net interface | awk '/^1/ { print $1 }' | cut -d. -f2)
        
                for n in $nics; do
                  # Define vlan name if none provided
                  if [[ -n ${config[dataVlanName${n}]} ]]; then
                    vlanName=${config[dataVlanName${n}]}
                  else
                    vlanName=$(printf "vlan%04d" $n)
                  fi
        
                  # Define vlan tag if none provided
                  if [[ -n ${config[dataVlanTag${n}]} ]]; then
                    vlanTag=${config[dataVlanTag${n}]}
                  else
                    vlanTag=$((4000 + $n))
                  fi
        
                  log "Assigning interface 1.$n to vlan $vlanName (tag: $vlanTag)"
                  test $DEBUG && log "tmsh create net vlan $vlanName tag $vlanTag interfaces add { 1.$n }"
                  tmsh create net vlan $vlanName tag $vlanTag interfaces add { 1.$n }
        
                  log "Assigning self-ip ${config[dataVlanAddr${n}]} to vlan $vlanName"
                  test $DEBUG && tmsh create net self ${config[dataVlanAddr${n}]}/${config[dataVlanCidr${n}]} vlan $vlanName
                  tmsh create net self ${config[dataVlanAddr${n}]}/${config[dataVlanCidr${n}]} vlan $vlanName
                done
              }
        
        
        
              # Assign data-plane gateway
              function create_default_route() {
                if [[ -n ${config[dataGtwy]} ]]; then
                  log "$(date +%T) Creating default route"
                  test $DEBUG && log "tmsh create net route default gw ${config[dataGtwy]}"
                  tmsh create net route default gw ${config[dataGtwy]}
                fi
              }
        
              # Enable managment access to first vlan self-ip
              function enable_mgmt_access() {
                # Allow SSH and management on first self-ip
                if [[ ${config[dataVlanAddr1]} ]]; then
                  log "$(date +%T) Enabling SSH and HTTPS access to first data-plane IP address"
                  test $DEBUG && log "tmsh modify net self ${config[dataVlanAddr1]}/${config[dataVlanCidr1]} allow-service add { tcp:443 tcp:22 }"
                  tmsh modify net self ${config[dataVlanAddr1]}/${config[dataVlanCidr1]} allow-service add { tcp:443 tcp:22 }
                fi
              }
        
        
              # Create tmm_init.tcl to associate Mellanox cx6 with cx5 drivers
              function create_tmm_init() {
                log "$(date +%T) Re-mapping ConnectX-6 to the ConnectX-5 driver" 
                echo 'device driver vendor_dev 15b3:101e mlxvf5' > /config/tmm_init.tcl
        
                # restart TMM to read the tmm_init.tcl and wait for it to be ready before proceeding
                tmsh restart sys service tmm
                wait_bigip_ready
              }
        
              # Create cli environment file, if defined
              function mk_cli_env() {
                if [[ -n ${config[envFile]} ]]; then
                  log "$(date +%T) Environment file defined, writing to /shared/env.ltm"
                  echo ${config[envFile]} | base64 -d > /shared/env.ltm
        
                  homes="/root /home/admin"
        
                  for home in $homes; do
                    echo "source /shared/env.ltm" >> $home/.bash_profile
                    sed -i  's/^cd \/config/#cd \/config/' $home/.bash_profile
                  done
                else
                  log "$(date +%T) Environment file undefined, skipping environment customization"
                fi
              }
        
              # Apply license
              function activate_license() {
                if [[ -n ${config[regKey]} ]]; then
                  log "$(date +%T) Attempting to activate license: ${config[regKey]}"
                  if [[ -n ${config[proxyAddr]} && -n ${config[proxyPort]} && -n ${config[proxyProtocol]} ]]; then
                    log "$(data +%T) Proxy: ${config[proxyAddr]}:${config[proxyPort]}"
                    log "SOAPLicenseClient --proxy ${config[proxyProtocol]}://${config[proxyAddr]}:${config[proxyPort]} --basekey ${config[regKey]}"
                    SOAPLicenseClient --proxy ${config[proxyProtocol]}://${config[proxyAddr]}:${config[proxyPort]} --basekey ${config[regKey]}
                  else
                    log "$(date +%T) Not using proxy"
                    log "SOAPLicenseClient --basekey ${config[regKey]}"
                    SOAPLicenseClient --basekey ${config[regKey]}
                  fi
                else
                  log "$(date +%T) RegKey not defined, skipping license activation"
                fi
              }
        
        
        
              ###
              ### Main
              ###
        
              # Source bigip ready functions
              source /usr/lib/bigstart/bigip-ready-functions
              # Wait for bigip to be ready to execute
              wait_bigip_ready
              log "$(date +%T) wait_bigip_ready() returned, proceeding with configuration"
              
              # Mount disk for logging
              mount_logdisk

              # Create cloud-init dump location and configure addressing
              # Placeholder for future use. Not terribly useful at the moment
              #create_ci_dir
        
              ## Mount podinfo volume
              #mount_podinfo
              ## Get pod network address
              #get_pod_addr
              ## Get general ltm configuration variables
              #get_ltm_cfg
              ## unmount podinfo volume
              #unmount_podinfo

        
              # Create tmm_init.tcl and restart tmm
              update_global
              assign_mgmt_addr
              inject_pubkey
              update_credentials
              mk_cli_env
              create_tmm_init
        
              # If interface mac-addresses were provided in config-map, assign interfaces to vlans
              # based on their mac address. Otherwise, assign interfaces based on presentation order.
              if [[ ${config[dataVlanMac1]} ]]; then
                log "$(date +%T) Found 'dataVlanMac1', assigning interfaces to vlans by mac-address"
                create_dataplane_by_mac
              else
                log "$(date +%T) 'dataVlanMac1' not found, assigning interfaces to vlans by presentation order"
                create_dataplane_by_order
              fi
        
              create_default_route
              enable_mgmt_access
        
              # Save configuration
              log "$(date +%T) Saving configuration"
              tmsh save sys config
        
              # Activate license
              activate_license
        
        
        runcmd: [nohup sh -c '/shared/cloud_init.bash' &]
        
