#!/bin/bash

# post install on local env

export DEBIAN_FRONTEND=noninteractive

echo Doing post-install steps for local env...
echo -----------------------------------------------------------------------------

required_packages="build-essential \
    dpkg-dev \
    keychain \
    libpcre3-dev \
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

# Yarn installation
printf '%-72s' "Installing ${package}..."
[ -f pubkey.gpg ] && rm pubkey.gpg
curl -LSsO https://dl.yarnpkg.com/debian/pubkey.gpg
check_result $? 'Yarn key could not be downloaded!'
apt-key add pubkey.gpg &> /dev/null
check_result $? 'Yarn key could not be added!'
rm pubkey.gpg

echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
apt-get -qq update
apt-get -qq install yarn
echo done.

echo -----------------------------------------------------------------------------
echo 'Done post-install steps for local dev.'
