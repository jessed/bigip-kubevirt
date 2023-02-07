#! /bin/bash

k8s_vars='v_k8s.txt'
common_vars='v_common.txt'
instance_vars='v_bigip.txt'
yaml_base='v_pod_yaml.template'
ci_template='v_cloud_init.template'
netDataFile='v_netconfig.yaml'

# output files
ciDataFile='cidata.yaml'
pod_file='pod.yaml'

# define common variables
source $common_vars

# define instance variables
source $instance_vars

# define K8s variables
source $k8s_vars


mk_cloud_init() {
  # Create the cloud-init using the template file
  # Use perl to replace all template variables
  # output to base64 to stop the newlines from being stripped
  cloud_init_b64=$(perl -pe 's;(\\*)(\$\{([a-zA-Z_][a-zA-Z_0-9]*)\})?;substr($1,0,int(length($1)/2)).($2&&length($1)%2?$2:$ENV{$3||$4});eg' $ci_template | base64 -w0)

  # create local copy to create userdata secret
  echo $cloud_init_b64 | base64 -d > $ciDataFile
}

mk_userdata_secret() {
  userdataStatus=$(kubectl get secret $userdataName 2>/dev/null)
  if [[ $? == 0 ]]; then kubectl delete secret $userdataName; fi
  if [[ $? == 0 ]]; then kubectl create secret generic $userdataName --from-file=userdata=$ciDataFile; fi
}

mk_networkdata_secret() {
  networkdataStatus=$(kubectl get secret $networkConfigName 2>/dev/null)
  if [[ $? == 0 ]]; then kubectl delete secret $networkConfigName; fi
  if [[ $? == 0 ]]; then kubectl create secret generic $networkConfigName --from-file=networkdata=$netDataFile; fi
}

mk_pod_yaml() {
  pod_yaml_b64=$(perl -pe 's;(\\*)(\$\{([a-zA-Z_][a-zA-Z_0-9]*)\})?;substr($1,0,int(length($1)/2)).($2&&length($1)%2?$2:$ENV{$3||$4});eg' $yaml_base | base64 -w0)

  # create local pod yaml for kubectl command
  echo $pod_yaml_b64 | base64 -d > $pod_file
}


## Main
##

mk_cloud_init
mk_userdata_secret
mk_networkdata_secret
mk_pod_yaml
