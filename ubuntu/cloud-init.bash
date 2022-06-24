#cloud-config

write-files:
  - path: /tmp/cloud_init.bash
    permissions: 0755
    owner: root:root
    content: |
      #! /bin/bash
      DEBUG=1

      # create an associative array to hold cloud-init variables
      declare -A config

      # Write a test file
      echo "Hello World" >> /home/jessed/README.txt

      podInfoDir="/run/podinfo"
      ciInfoDir="/run/ciInfo"

      ##
      ## Functions
      ##
      function mount_podInfo() {
        if [[ ! -d $podInfoDir ]]; then mkdir $podInfoDir; fi
        mount /dev/vdc $podInfoDir
        
        if [[ ! -d $ciInfoDir ]]; then mkdir $ciInfoDir; fi
        mount /dev/vdd $ciInfoDir
      }

      function unmount_podInfo() {
        umount $podInfoDir
        umount $ciInfoDir
        rmdir $podInfoDir $ciInfoDir
      }

      function get_ci_vars() {
        if [[ -d $ciInfoDir ]]; then
          for k in $(ls -1 $ciInfoDir); do
            v=$(cat $ciInfoDir/$k)
            config[$k]=$v
          done

          echo "$(date +%T) Successfully sources cloud-init variables from $ciInfoDir"

          for k in ${!config[*]}; do
            printf "%40s -> %40s\n" $k ${config[$k]} >> /tmp/config-map.txt
          done
        else
          echo "$(date +%T) ERROR: $ciInfoDir not found, cloud-init variables unavailable"
        fi
      }

      function set_hostname() {
        echo "${config[hostname]}" > /etc/hostname
        hostname -F /etc/hostnam
      }

      


      ##
      ## Main
      ##

      mount_podInfo
      get_ci_vars
      unmount_podInfo

      set_hostname

runcmd:
  - /tmp/cloud_init.bash



