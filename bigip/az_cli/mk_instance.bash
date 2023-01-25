#l /usr/bin/bash

###
### Variables
###
# Source AODS variables

if [[ -z $1 ]]; then
  echo "ERROR: instance variable file not provided"
  echo "USAGE: $0 <instance_variables_file"
  exit 1
fi

instance_vars=$1
common_vars="v_common_bigip.txt"
aods_vars="v_aods.txt"
aods_vm_base="v_vm-template.txt"
ci_template="v_cloud-init.template"
cloud_init_def=""
DEBUG=1

source $aods_vars
source $common_vars
source $instance_vars


###
### Functions
###

mk_cloud_init() {
  cloud_init_b64=$(perl -pe 's;(\\*)(\$\{([a-zA-Z_][a-zA-Z_0-9]*)\})?;substr($1,0,int(length($1)/2)).($2&&length($1)%2?$2:$ENV{$3||$4});eg' $ci_template | base64 -w0)
  
  # create a decoded copy of the cloud-init for inspection
  [[ $DEBUG ]] && { printf "%s" $cloud_init_b64 | base64 -d > working/ci_data.bash; }
}

# Create the VM parameters
mk_vm_parameters() {
  source $aods_vm_base

  [[ $DEBUG ]] && { echo -n $vm_parameters > working/vm_params.json; }

}



###
### Main
###

# Create the cloud-init script with embedded variables
mk_cloud_init

# Create the vm_parameters JSON blob.
# This uses the output of 'mk_cloud_init' and must come second
mk_vm_parameters 

tee << EOF > az_command.bash
az networkcloud virtualmachine create --name $vmName \
--resource-group $myrg \
--subscription $mysub \
--virtual-machine-parameters '$vm_parameters' \
--debug
EOF
