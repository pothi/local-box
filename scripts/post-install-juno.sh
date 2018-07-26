#!/bin/bash

# post install on Juno (Elementary OS)

export DEBIAN_FRONTEND=noninteractive

echo Doing post-install steps for Juno...
echo -----------------------------------------------------------------------------

# Gcloud initialization
export CLOUD_SDK_REPO="cloud-sdk-bionic"
echo "deb http://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" | sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
apt-get -qq update

required_packages="haveged \
    ethtool \
    google-cloud-sdk"

for package in $required_packages
do
    printf '%-72s' "Installing ${package}..."
    apt-get -qq install $package &> /dev/null
    echo done.
done

echo -----------------------------------------------------------------------------
echo 'Done post-install steps for Juno.'
