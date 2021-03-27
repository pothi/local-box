#!/bin/bash

# Variables - you may send these as command line options
# dev_user
# no passwd is set for this user

[ -f /root/.envrc ] && source /root/.envrc

echo 'Creating a "web developer" user to login via SFTP...'

if [ "$dev_user" == "" ]; then
    # create SFTP username automatically
    dev_user="dev_$(pwgen -A 8 1)"
    echo "export dev_user=$dev_user" >> /root/.envrc
fi

#--- please do not edit below this file ---#

if [ ! -d "/home/$dev_user" ]; then
    useradd --shell=/bin/bash -m --home-dir /home/$dev_user $dev_user

    groupadd $dev_user
else
    echo "The default directory /home/$dev_user already exists! Trying to add user anyway..."
    useradd --shell=/bin/bash -m --home-dir /home/$dev_user $dev_user &> /dev/null

    groupadd $dev_user &> /dev/null
    # exit 1
fi # end of if ! -d "/home/$dev_user" - whoops

# cp $local_wp_in_a_box_repo/.envrc-user-sample /home/$dev_user/.envrc
# chown $dev_user:$dev_user /home/$dev_user/.envrc

# cd $local_wp_in_a_box_repo/scripts/ &> /dev/null
# sudo -H -u $dev_user bash nvm-nodejs.sh
# cd - &> /dev/null

echo ...done setting up Developer!
