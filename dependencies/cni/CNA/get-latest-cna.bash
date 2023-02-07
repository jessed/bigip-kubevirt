#! /bin/bash

REL="v0.85.0"
URL='https://github.com/kubevirt/cluster-network-addons-operator/releases/download'


dir=$REL
files="namespace.yaml network-addons-config.crd.yaml operator.yaml"
example="network-addons-config-example.cr.yaml"

test -d $REL || { mkdir $REL; }

# Download installation files
declare -a install_files
for f in $files; do
  wget -q ${URL}/${REL}/$f -O $dir/$f
  if [[ $? == 0 ]]; then
    install_files+=($f)
  else
    echo "Failed to downlod $f"
  fi
done

echo -e "\n\nInstall with:"
for f in ${install_files[@]}; do
  echo "kubectl apply -f $dir/$f"
done

# Download example CR
wget -q ${URL}/$example -O $dir/$example

if [[ $? == 0 ]]; then
tee << EOF
Downloaded example operator CR: $dir/$example
Deploy the opeator CR after customizing
An example of a customized operator CR can be found in the examples directory,

EOF
fi
