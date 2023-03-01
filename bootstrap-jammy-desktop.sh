#!/usr/bin/env bash

# programming env: these switches turn some bugs into errors
# set -o errexit -o pipefail -o noclobber -o nounset

# Version: 1.0

# to be run as root, probably as a user-script just after a server is installed
# https://stackoverflow.com/a/52586842/1004587
# also see https://stackoverflow.com/q/3522341/1004587
is_user_root () { [ "${EUID:-$(id -u)}" -eq 0 ]; }
[ is_user_root ] || { echo 'You must be root or have sudo privilege to run this script. Exiting now.'; exit 1; }

export PATH=~/bin:~/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin
export DEBIAN_FRONTEND=noninteractive

# attempt to create the backups directory, if it doesn't exist
[ -d "~/backups" ] || mkdir -p ~/backups

echo "Script started on (date & time): $(date +%c)"

# Function to exit with an error message
check_result() {
    if [ $? -ne 0 ]; then
        echo; echo "Error: $1"; echo
        exit 1
    fi
}

# function to configure timezone to UTC
set_utc_timezone() {
    if [ "$(date +\%Z)" != "UTC" ] ; then
        [ ! -f /usr/sbin/tzconfig ] && apt-get -qq install tzdata > /dev/null
        printf '%-72s' "Setting up timezone..."
        ln -fs /usr/share/zoneinfo/UTC /etc/localtime
        dpkg-reconfigure -f noninteractive tzdata
        # timedatectl set-timezone UTC
        check_result $? 'Error setting up timezone.'

        # Recommended to restart cron after every change in timezone
        systemctl restart cron
        check_result $? 'Error restarting cron daemon after changing timezone.'
        echo done.
    fi
}

# refresh apt cache, if it is older than 24 hours
refresh_apt_cache() {
    # Taken from Ansible - https://askubuntu.com/a/1362550/65814
    APT_UPDATE_SUCCESS_STAMP_PATH=/var/lib/apt/periodic/update-success-stamp
    APT_LISTS_PATH=/var/lib/apt/lists
    if [ -f "$APT_UPDATE_SUCCESS_STAMP_PATH" ]; then
        if [ -z "$(find "$APT_UPDATE_SUCCESS_STAMP_PATH" -mmin -1440 2> /dev/null)" ]; then
                printf '%-72s' "Updating apt cache"
                apt-get -qq update
                echo done.
        fi
    elif [ -d "$APT_LISTS_PATH" ]; then
        if [ -z "$(find "$APT_LISTS_PATH" -mmin -360 2> /dev/null)" ]; then
                printf '%-72s' "Updating apt cache"
                apt-get -qq update
                echo done.
        fi
    fi

    if [ ! -f "$HOME/.envrc" ]; then
        touch ~/.envrc
        chmod 600 ~/.envrc
    else
        . ~/.envrc
    fi
}

git_usermail=${ADMIN_EMAIL:-1254302+pothi@users.noreply.github.com}
git_username=${ADMIN_NAME:-"Pothi Kalimuthu"}
git config --global --replace-all user.email $git_usermail
git config --global --replace-all user.name $git_username

#--- apt tweaks ---#

# Ref: https://wiki.debian.org/Multiarch/HOWTO
# https://askubuntu.com/a/1336013/65814
[ ! $(dpkg --get-selections | grep -q i386) ] && dpkg --remove-architecture i386 2>/dev/null

# Fix apt ipv4/6 issue
[ ! -f /etc/apt/apt.conf.d/1000-force-ipv4-transport ] && \
    echo 'Acquire::ForceIPv4 "true";' > /etc/apt/apt.conf.d/1000-force-ipv4-transport

# Fix a warning related to dialog
# run `debconf-show debconf` to see the current /default selections.
echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

add-apt-repository --yes --no-update --ppa ppa:ondrej/php >/dev/null
add-apt-repository --yes --no-update --ppa ppa:ansible/ansible >/dev/null

refresh_apt_cache

echo -------------------------- Prerequisites ------------------------------------
# apt-utils to fix an annoying non-critical bug on minimal images. Ref: https://github.com/tianon/docker-brew-ubuntu-core/issues/59
# apt-get -qq install apt-utils &> /dev/null

required_packages="fail2ban \
    vim"

for package in $required_packages
do
    if dpkg-query -W -f='${status}' $package 2>/dev/null | grep -q "ok installed"
    then
        # echo "'$package' is already installed"
        :
    else
        printf '%-72s' "Installing '${package}' ..."
        apt-get -qq install $package > /dev/null
        check_result "Error: couldn't install $package."
        echo done.
    fi
done

# --classic riseup-vpn
required_snap_packages="at \
    authy \
    riseup-vpn \
    shellcheck \
    xclip"

for package in $required_snap_packages
do
    printf '%-72s' "Installing '${package}' ..."
    snap install $package > /dev/null
    check_result "Error: couldn't install $package."
    echo done.
done

#--- setup timezone ---#
# To be skipped for desktop
# set_utc_timezone

# Create a WordPress user with /home/web as $HOME
wp_user=${WP_USERNAME:-""}
[ ! $wp_user ] && echo "Define WP_USERNAME in ~/.envrc and run the script!"
# To be skipped for desktop env

# Create password for WP User
# To be skipped for desktop env

# provide sudo access without passwd to WP User
# To be skipped for desktop env

# Enable password authentication for WP User
# To be skipped for desktop env

# echo -------------------------------- LEMP ---------------------------------------

# echo ------------------------------- MySQL ---------------------------------------
# MySQL is required by PHP. So, install it before PHP

package=default-mysql-server
if dpkg-query -W -f='${Status}' $package 2>/dev/null | grep -q "ok installed"
then
    # echo "'$package' is already installed."
    :
else
    printf '%-72s' "Installing '${package}' ..."
    apt-get -qq install $package > /dev/null
    check_result "Error: couldn't install $package."
    echo done.
fi

# Create a MySQL admin user
if [ "$MYSQL_ADMIN_USER" == "" ]; then
printf '%-72s' "Creating a MySQL Admin User..."
    # create MYSQL username automatically
    # unique username / password generator: https://unix.stackexchange.com/q/230673/20241
    MYSQL_ADMIN_USER="mysql_$(openssl rand -base64 32 | tr -d /=+ | cut -c -10)"
    MYSQL_ADMIN_PASS=$(openssl rand -base64 32 | tr -d /=+ | cut -c -20)
    echo "export MYSQL_ADMIN_USER=$MYSQL_ADMIN_USER" >> /root/.envrc
    echo "export MYSQL_ADMIN_PASS=$MYSQL_ADMIN_PASS" >> /root/.envrc
    mysql -e "CREATE USER ${MYSQL_ADMIN_USER} IDENTIFIED BY '${MYSQL_ADMIN_PASS}';"
    mysql -e "GRANT ALL PRIVILEGES ON *.* TO ${MYSQL_ADMIN_USER} WITH GRANT OPTION"
echo done.
echo "Please check ~/.envrc for credentials."
fi

echo -------------------------------- PHP ----------------------------------------
# PHP is required by Nginx to configure the defaults. So, install it before Nginx

php_ver=8.2
lemp_packages="php${php_ver}-fpm \
    php${php_ver}-mysql \
    php${php_ver}-gd \
    php${php_ver}-cli \
    php${php_ver}-xml \
    php${php_ver}-mbstring \
    php${php_ver}-soap \
    php${php_ver}-curl \
    php${php_ver}-zip \
    php${php_ver}-bcmath \
    php${php_ver}-intl \
    php${php_ver}-imagick"

for package in $lemp_packages
do
    if dpkg-query -W -f='${Status}' $package 2>/dev/null | grep -q "ok installed"
    then
        # echo "'$package' is already installed"
        :
    else
        # Remove ${php_ver} from package name to find if php-package is installed.
        php_package=$(printf '%s' "$package" | sed 's/[.0-9]*//g')
        if dpkg-query -W -f='${Status}' $php_package 2>/dev/null | grep -q "ok installed"
        then
            echo "'$package' is already installed as $php_package."
            :
        else
            printf '%-72s' "Installing '${package}' ..."
            apt-get -qq install $package > /dev/null
            check_result $? "Error installing ${package}."
            echo done.
        fi
    fi
done

# specific to desktop and dev servers
package=php${php_ver}-xdebug
if dpkg-query -W -f='${Status}' $package 2>/dev/null | grep -q "ok installed"
then
    echo "'$package' is already installed."
    :
else
    apt-get -qq install $package > /dev/null
fi

# . $local_wp_in_a_box_repo/scripts/php-installation.sh
php_user=$wp_user
fpm_ini_file=/etc/php/${php_ver}/fpm/php.ini
pool_file=/etc/php/${php_ver}/fpm/pool.d/${php_user}.conf
PM_METHOD=ondemand

user_mem_limit=${PHP_MEM_LIMIT:-""}
[ -z "$user_mem_limit" ] && user_mem_limit=512

max_children=${PHP_MAX_CHILDREN:-""}

if [ -z "$max_children" ]; then
    # let's be safe with a minmal value
    sys_memory=$(free -m | grep -oP '\d+' | head -n 1)
    if (($sys_memory <= 600)) ; then
        max_children=4
    elif (($sys_memory <= 1600)) ; then
        max_children=6
    elif (($sys_memory <= 5600)) ; then
        max_children=10
    elif (($sys_memory <= 10600)) ; then
        PM_METHOD=static
        max_children=20
    elif (($sys_memory <= 20600)) ; then
        PM_METHOD=static
        max_children=40
    elif (($sys_memory <= 30600)) ; then
        PM_METHOD=static
        max_children=60
    elif (($sys_memory <= 40600)) ; then
        PM_METHOD=static
        max_children=80
    else
        PM_METHOD=static
        max_children=100
    fi
fi

env_type=${ENV_TYPE:-""}
if [[ $env_type = "local" ]]; then
    PM_METHOD=ondemand
fi

echo "Configuring memory limit to ${user_mem_limit}MB"
sed -i -e '/^memory_limit/ s/=.*/= '$user_mem_limit'M/' $fpm_ini_file

user_max_filesize=${PHP_MAX_FILESIZE:-64}
echo "Configuring 'post_max_size' and 'upload_max_filesize' to ${user_max_filesize}MB..."
sed -i -e '/^post_max_size/ s/=.*/= '$user_max_filesize'M/' $fpm_ini_file
sed -i -e '/^upload_max_filesize/ s/=.*/= '$user_max_filesize'M/' $fpm_ini_file

user_max_input_vars=${PHP_MAX_INPUT_VARS:-5000}
echo "Configuring 'max_input_vars' to $user_max_input_vars (from the default 1000)..."
sed -i '/max_input_vars/ s/;\? \?\(max_input_vars \?= \?\)[[:digit:]]\+/\1'$user_max_input_vars'/' $fpm_ini_file

# Setup timezone
user_timezone=${USER_TIMEZONE:-UTC}
echo "Configuring timezone to $user_timezone ..."
sed -i -e 's/^;date\.timezone =$/date.timezone = "'$user_timezone'"/' $fpm_ini_file
export PHP_PCNTL_FUNCTIONS='pcntl_alarm,pcntl_fork,pcntl_waitpid,pcntl_wait,pcntl_wifexited,pcntl_wifstopped,pcntl_wifsignaled,pcntl_wifcontinued,pcntl_wexitstatus,pcntl_wtermsig,pcntl_wstopsig,pcntl_signal,pcntl_signal_get_handler,pcntl_signal_dispatch,pcntl_get_last_error,pcntl_strerror,pcntl_sigprocmask,pcntl_sigwaitinfo,pcntl_sigtimedwait,pcntl_exec,pcntl_getpriority,pcntl_setpriority,pcntl_async_signals,pcntl_unshare'
export PHP_EXEC_FUNCTIONS='escapeshellarg,escapeshellcmd,exec,passthru,proc_close,proc_get_status,proc_nice,proc_open,proc_terminate,shell_exec,system'
sed -i "/disable_functions/c disable_functions = ${PHP_PCNTL_FUNCTIONS},${PHP_EXEC_FUNCTIONS}" $fpm_ini_file

[ ! -f $pool_file ] && cp /etc/php/${php_ver}/fpm/pool.d/www.conf $pool_file
[ -f "/etc/php/${php_ver}/fpm/pool.d/www.conf" ] && \
    mv /etc/php/${php_ver}/fpm/pool.d/www.conf ~/backups/${php_ver}-www.conf
sed -i -e 's/^\[www\]$/['$php_user']/' $pool_file
sed -i -e 's/www-data/'$php_user'/' $pool_file
sed -i -e '/^;listen.\(owner\|group\|mode\)/ s/^;//' $pool_file
sed -i -e '/^listen.mode = / s/[0-9]\{4\}/0666/' $pool_file

# php_ver = 5.6, 7.0, 8.0, 8.1, etc
php_socket=/run/php/php${php_ver}-fpm-${php_user}.sock
sed -i "/^listen =/ s:=.*:= $php_socket:" $pool_file

sed -i -e 's/^pm = .*/pm = '$PM_METHOD'/' $pool_file
sed -i '/^pm.max_children/ s/=.*/= '$max_children'/' $pool_file

PHP_MIN=$(expr $max_children / 10)

sed -i '/^;catch_workers_output/ s/^;//' $pool_file
sed -i '/^;pm.process_idle_timeout/ s/^;//' $pool_file
sed -i '/^;pm.max_requests/ s/^;//' $pool_file
sed -i '/^;pm.status_path/ s/^;//' $pool_file
sed -i '/^;ping.path/ s/^;//' $pool_file
sed -i '/^;ping.response/ s/^;//' $pool_file

# home_basename=web
# home_basename=$(echo $wp_user | awk -F _ '{print $1}')
# [ -z $home_basename ] && home_basename=web
# [ ! -d /home/${home_basename}/log ] && mkdir /home/${home_basename}/log
PHP_SLOW_LOG_PATH="/var/log/slow-php.log"
sed -i '/^;slowlog/ s/^;//' $pool_file
sed -i '/^slowlog/ s:=.*$: = '$PHP_SLOW_LOG_PATH':' $pool_file
sed -i '/^;request_slowlog_timeout/ s/^;//' $pool_file
sed -i '/^request_slowlog_timeout/ s/= .*$/= 60/' $pool_file

FPMCONF="/etc/php/${php_ver}/fpm/php-fpm.conf"
sed -i '/^;emergency_restart_threshold/ s/^;//' $FPMCONF
sed -i '/^emergency_restart_threshold/ s/=.*$/= '$PHP_MIN'/' $FPMCONF
sed -i '/^;emergency_restart_interval/ s/^;//' $FPMCONF
sed -i '/^emergency_restart_interval/ s/=.*$/= 1m/' $FPMCONF
sed -i '/^;process_control_timeout/ s/^;//' $FPMCONF
sed -i '/^process_control_timeout/ s/=.*$/= 10s/' $FPMCONF

# restart php upon OOM or other failures
# ref: https://stackoverflow.com/a/45107512/1004587
# TODO: Do the following only if "Restart=on-failure" is not found in that file.
sed -i '/^\[Service\]/!b;:a;n;/./ba;iRestart=on-failure' /lib/systemd/system/php${php_ver}-fpm.service
systemctl daemon-reload
check_result $? "Could not update /lib/systemd/system/php${php_ver}-fpm.service file!"

printf '%-72s' "Restarting PHP-FPM..."
/usr/sbin/php-fpm${php_ver} -t 2>/dev/null && systemctl restart php${php_ver}-fpm
echo done.

echo ------------------------------- Nginx ---------------------------------------
# php_ver is required from PHP

package=nginx-extras
if dpkg-query -W -f='${Status}' $package 2>/dev/null | grep -q "ok installed"
then
    echo "'$package' is already installed."
    :
else
    apt-get -qq install $package > /dev/null
fi

# Download WordPress Nginx repo
[ ! -d ~/tmp/wp-nginx ] && {
    mkdir -p ~/tmp/wp-nginx
    wget -q -O- https://github.com/pothi/wordpress-nginx/tarball/main | tar -xz -C ~/tmp/wp-nginx --strip-components=1
    cp -a ~/tmp/wp-nginx/{conf.d,errors,globals,sites-available} /etc/nginx/
    [ ! -d /etc/nginx/sites-enabled ] && mkdir /etc/nginx/sites-enabled
    ln -fs /etc/nginx/sites-available/default.conf /etc/nginx/sites-enabled/default.conf
}

# Remove the default conf file supplied by OS
[ -f /etc/nginx/sites-enabled/default ] && rm /etc/nginx/sites-enabled/default

# Remove the default SSL conf to support latest SSL conf.
# It should hide two lines starting with ssl_
# ^ starting with...
# \s* matches any number of space or tab elements before ssl_
# when run more than once, it just doesn't do anything as the start of the line is '#' after the first execution.
sed -i 's/^\s*ssl_/# &/' /etc/nginx/nginx.conf 

# create dhparam
if [ ! -f /etc/nginx/dhparam.pem ]; then
    openssl dhparam -dsaparam -out /etc/nginx/dhparam.pem 4096 &> /dev/null
    sed -i 's:^# \(ssl_dhparam /etc/nginx/dhparam.pem;\)$:\1:' /etc/nginx/conf.d/ssl-common.conf
fi

# php_ver = 5.6, 7.0, 8.0, 8.1, etc
# php_ver_nodot = 56, 70, 80, 81, 82, etc
php_ver_nodot=$(echo $php_ver | sed 's/\.//')
php_socket=/run/php/php${php_ver}-fpm-${php_user}.sock
# [ -f /etc/nginx/conf.d/lb.conf ] && sed -i "s:/var/lock/php-fpm.*;:$php_socket;:" /etc/nginx/conf.d/lb.conf
[ -f /etc/nginx/conf.d/lb.conf ] && rm /etc/nginx/conf.d/lb.conf
[ ! -f /etc/nginx/conf.d/fpm.conf ] && \
    echo "upstream fpm { server unix:$php_socket; }" > /etc/nginx/conf.d/fpm.conf
[ ! -f /etc/nginx/conf.d/fpm${php_ver}.conf ] && \
    echo "upstream fpm${php_ver} { server unix:$php_socket; }" > /etc/nginx/conf.d/fpm${php_ver}.conf

printf '%-72s' "Restarting Nginx..."
/usr/sbin/nginx -t 2>/dev/null && systemctl restart nginx
echo done.

echo --------------------------- DNSMASQ -----------------------------------------
# TODO: get PRIMARY_DOMAIN to improve the following to replace example.com below...
package=dnsmasq
if dpkg-query -W -f='${Status}' $package 2>/dev/null | grep -q "ok installed"
then
    # echo "'$package' is already installed."
    :
else
    printf '%-72s' "Installing '${package}' ..."
    apt-get -qq install $package &> /dev/null
    # the above will result in an error as systemd-resolvd is already listening on the same port as dnsmasq
    # check_result "Error: couldn't install $package."
    echo done.
fi
# Inspired by https://sixfeetup.com/blog/local-development-with-wildcard-dns-on-linux
# cp /etc/dnsmasq.conf /etc/systemd/resolved.conf ~/backups/
DNSMASQ_ADD=127.0.53.1
LOCAL_DOMAIN=${PRIMARY_DOMAIN:-"jammy.example.com"}
# sed -i "s:^# \?\(listen-address=\):\1$DNSMASQ_ADD:" /etc/dnsmasq.conf
# sed -i "s:^# \?\(bind-interfaces\):\1:" /etc/dnsmasq.conf

# Ref: https://wiki.archlinux.org/title/Dnsmasq
[ -f /etc/dnsmasq.d/listen-locally ] || \
    echo -e "bind-interfaces\nlisten-address=$DNSMASQ_ADD" > /etc/dnsmasq.d/listen-locally
[ -f /etc/dnsmasq.d/jammy ] || \
    echo "address=/.${LOCAL_DOMAIN}/$DNSMASQ_ADD" > /etc/dnsmasq.d/jammy
[ -f /etc/dnsmasq.d/custom-dns-servers ] || \
    echo -e "no-resolv\nserver=1.1.1.1\nserver=8.8.8.8" > /etc/dnsmasq.d/custom-dns-servers

systemctl restart dnsmasq

[ -d /etc/systemd/resolved.conf.d ] || mkdir /etc/systemd/resolved.conf.d
[ -f /etc/systemd/resolved.conf.d/dnsmasq-upstream.conf ] || \
    echo "DNS=$DNSMASQ_ADD" > /etc/systemd/resolved.conf.d/dnsmasq-upstream.conf
systemctl restart systemd-resolved


exit
echo 'this should not be displayed'

echo --------------------------- Certbot -----------------------------------------
# TODO: If PRIMARY_DOMAIN is supplied along with WILDCARD=true, then try to obtain wildcard cert.
snap install core
snap refresh core
apt-get -qq remove certbot
snap install --classic certbot
ln -fs /snap/bin/certbot /usr/bin/certbot

# register certbot account if email is supplied
if [ $CERTBOT_ADMIN_EMAIL ]; then
    certbot show_account &> /dev/null
    if [ "$?" != "0" ]; then
        certbot -m $CERTBOT_ADMIN_EMAIL --agree-tos --no-eff-email register
    fi
fi

[ ! -d /etc/letsencrypt/renewal-hooks/deploy/ ] && mkdir -p /etc/letsencrypt/renewal-hooks/deploy/
restart_script=/etc/letsencrypt/renewal-hooks/deploy/nginx-restart.sh
restart_script_url=https://github.com/pothi/snippets/raw/main/ssl/nginx-restart.sh
[ ! -f "$restart_script" ] && {
    wget -q -O $restart_script $restart_script_url
    check_result $? "Error downloading Nginx Restart Script for Certbot renewals."
    chmod +x $restart_script
}

echo --------------------------- Others -----------------------------------------
# Hide mounted drives in dock
# Ref: https://ubuntuhandbook.org/index.php/2022/02/easy-hide-mounted-drives-trash-ubuntu-2204/
gsettings set org.gnome.shell.extensions.dash-to-dock show-mounts-only-mounted false

printf '%-72s' "Installing etckeeper..."
# sending the output to /dev/null to reduce the noise
apt-get -qq install etckeeper > /dev/null
sed -i 's/^GIT_COMMIT_OPTIONS=""$/GIT_COMMIT_OPTIONS="--quiet"/' /etc/etckeeper/etckeeper.conf
echo done.

# https://forum.mikrotik.com/viewtopic.php?p=970317#p970317
printf '%-72s' "Configuring rsa support for ssh (client)..."
[ -f /etc/ssh/ssh_config.d/rsa-support.conf ] || \
    echo "PubkeyAcceptedAlgorithms +ssh-rsa" > /etc/ssh/ssh_config.d/rsa-support.conf
echo done.

# Fix for error with Ansible playbooks
# https://help.ubuntu.com/community/Locale#Changing_settings_permanently
printf '%-72s' "Configuring locales..."
    [ -f ~/.pam_environment ] || echo "en_IN.utf8" > ~/.pam_environment
echo done.
echo "Note: changes take effect only after a fresh login."

# TODO: Pull update-crontab.sh and create a new entry (automatically)

echo All done.

echo -----------------------------------------------------------------------------
echo You may find the credentials in /root/.envrc file.
echo -----------------------------------------------------------------------------

echo 'You may reboot only once to apply certain updates (ex: kernel updates)!'
echo

echo "Script ended on (date & time): $(date +%c)"
echo

