#l /usr/bin/bash

###
### Variables
###
# Source AODS variables

# define instance-specific variables here to allow for overriding defaults from vars.bash
aods_vars="aods-vars.txt"
aods_vm_base="aods-vm-template.txt"
instance_vars="bigip01.txt"
ci_template="cloud-init.template"
cloud_init_def=""
DEBUG=1

source $aods_vars
source $instance_vars


###
### Functions
###

mk_cloud_init() {
  cloud_init_b64=$(perl -pe 's;(\\*)(\$\{([a-zA-Z_][a-zA-Z_0-9]*)\})?;substr($1,0,int(length($1)/2)).($2&&length($1)%2?$2:$ENV{$3||$4});eg' $ci_template | base64 -w0)

  [[ $DEBUG ]] && { echo -n $cloud_init_b64 | base64 -d > ci_data.bash; }
}

# Create the VM parameters
mk_vm_parameters() {
  source $aods_vm_base

  [[ $DEBUG ]] && { echo -n $vm_parameters > vm_params.json; }

}



###
### Main
###

# Create the cloud-init script with embedded variables
mk_cloud_init

# Create the vm_parameters JSON blob.
# This uses the output of 'mk_cloud_init' and must come second
mk_vm_parameters 


#printf "$cloud_init_def" > 1.bash
#printf "$cloud_init_b64" > 1.b64
printf "$vm_parameters" > vm_params.json

#echo "az networkcloud virtualmachine create --name $vmName --resource-group $myrg --subscription $mysub --virtual-machine-parameters '$vm_parameters' --debug"

tee << EOF > az_command.bash
az networkcloud virtualmachine create --name $vmName \
--resource-group $myrg \
--subscription $mysub \
--virtual-machine-parameters '$vm_parameters' \
--debug
EOF
