#! /bin/bash

# This script will build the containerized VM using docker or podman (whichever is present).
# The qcow2 to be containerized should be located in this directory.

image_name="bigip-kv"
tag="1"
registry="k83:5000"

##
## Main
##

# Determine whether docker or podman should be used.
# For no particular reason, docker is checked first.
# Feel free to add additional entries as long as the build command uses the same
# syntax as docker and podman

docker_bin=$(which docker)
podman_bin=$(which podman)

if [[ -n $docker_bin ]]; then
  echo "Found docker"
  cmd=$docker_bin
elif [[ -n $podman_bin ]]; then
  echo "Found podman"
  cmd=$podman_bin
else
  echo -e "\nERROR: Failed to find either docker or podman, cannot proceed\n\n"
fi

# Build container
echo "Building container"
echo $cmd build -t ${registry}/${name}:${tag}
$cmd build -t ${registry}/${name}:${tag}

# Log error and exit if a build error occurred
if [[ $? -ne 0 ]]; then
  echo "ERROR: Container build error detected, not pushing to registry"
  exit 1
else
  echo "Container build succeeded, proceeding to push"
fi


# Push container to registry
echo "Container build succeeded, pushing image to repository"
echo $cmd push ${registry}/${name}:${tag}
$cmd push ${registry}/${name}:${tag}

# Check for and warn of errors
if [[ $? -ne 0 ]]; then
  echo "ERROR: Error detected in push to registry ($registry), push failed"
  exit 2
else
  echo "Container push succeeded"
  curl -sL ${registry}/tags/list | jq .
fi

