#! /bin/bash

URL='https://github.com/k8snetworkplumbingwg/multus-cni'

git clone --depth 1 ${URL}

test -f multus-cni/deployments/multus-daemonset-thick.yml && { ln -s multus-cni/deployments/multus-daemonset-thick.yml .; }

if [[ -f multus-cni/deployments/multus-daemonset-thick.yml ]]; then
  if [[ ! -f multus-daemonset-thick.yml ]]; then
    ln -s multus-cni/deployments/multus-daemonset-thick.yml multus-daemonset-thick.yml
  fi
  echo -e "\n\nInstall with:"
  echo "kubectl create -f multus-daemonset-thick.yml"
else
  echo "Possible error in git clone: 'multus-cni/deployments/multus-daemonset-thick.yml' not found"
  echo "Check multus-cni/deployments for 'multus-daemonset-thick.yml'"
fi
