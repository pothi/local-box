#!/bin/bash

# post install on local env

export DEBIAN_FRONTEND=noninteractive

echo Doing post-install steps for local env...
echo -----------------------------------------------------------------------------

required_packages="lxd \
    php-xdebug \
    vim-scripts"

for package in $required_packages
do
    printf '%-72s' "Installing ${package}..."
    apt-get -qq install $package &> /dev/null
    echo done.
done

echo -----------------------------------------------------------------------------
echo 'Done post-install steps for local dev.'
