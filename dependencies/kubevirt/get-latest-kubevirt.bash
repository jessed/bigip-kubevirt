#! /bin/bash

REL='v0.54.0'
URL='https://github.com/kubevirt/kubevirt/releases/download'

files='kubevirt-operator.yaml kubevirt-cr.yaml'

msg=""
declare -a install_files
for f in $files; do
  component=$(echo $f | cut -d '-' -f 2 | cut -d '.' -f 1)
  name="kubevirt-${REL}-${component}.yaml"
  wget -q ${URL}/${REL}/${f} -O $name
  if [[ $? == 0 ]]; then echo "Downloaded $f as $name"; fi
  install_files+=($name)
done


echo -e "\n\nInstall with:"
for c in ${install_files[@]}; do
  echo "kubectl create -f $c"
done
