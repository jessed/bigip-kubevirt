#! /bin/bash

# Downloads the 'operator' and 'cr' yaml files necesary to deploy kubevirt
# for the specified release

REL='v0.58.0'
URL='https://github.com/kubevirt/kubevirt/releases/download'

files='kubevirt-operator.yaml kubevirt-cr.yaml'

# Create the version directory if it is not already present
#dir=$(echo $REL | awk 'BEGIN { FS="." } { print $2"."$3 }')
dir=$REL
test -d $dir || { mkdir $dir; }

declare -a install_files
for f in $files; do
  component=$(echo $f | cut -d '-' -f 2 | cut -d '.' -f 1)
  name="kubevirt-${REL}-${component}.yaml"
  wget -q ${URL}/${REL}/${f} -O $dir/$name
  if [[ $? == 0 ]]; then echo "Downloaded $f as $name"; fi
  install_files+=($name)
done

echo -e "\n\nInstall with:"
for c in ${install_files[@]}; do
  echo "kubectl create -f $c"
done
