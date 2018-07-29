#!/bin/bash

# post install on local env

export DEBIAN_FRONTEND=noninteractive

echo Doing post-install steps for local env...
echo -----------------------------------------------------------------------------

required_packages="keychain \
    lxd \
    mailutils \
    net-tools \
    nmap \
    php-xdebug \
    ruby ruby-dev zlib1g-dev \
    screen \
    ssh \
    vim-scripts"

for package in $required_packages
do
    printf '%-72s' "Installing ${package}..."
    apt-get -qq install $package &> /dev/null
    echo done.
done

sudo lxd init --auto
sudo gpasswd -a $user lxd
newgrp lxd

echo -----------------------------------------------------------------------------
echo 'Done post-install steps for local dev.'
