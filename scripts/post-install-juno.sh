#!/bin/bash

# post install on Juno (Elementary OS)

export DEBIAN_FRONTEND=noninteractive

echo Doing post-install steps for Juno...
echo -----------------------------------------------------------------------------

required_packages="haveged \
    ethtool"

for package in $required_packages
do
    printf '%-72s' "Installing ${package}..."
    apt-get -qq install $package &> /dev/null
    echo done.
done

echo -----------------------------------------------------------------------------
echo 'Done post-install steps for Juno.'
