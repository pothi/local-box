# Local Development Box

Script/s to install L(E/A)MP in a local server, aimed towards local development of PHP / WordPress sites.

## Supported Platforms

+ Juno (Elementary OS)
+ Pop!OS
+ Ubuntu 18.04

## Generic Goals

In sync with WordPress philosophy of “[decision, not options](https://wordpress.org/about/philosophy/)”.

## Performance Checklist

- Redis for object cache (with memcached as an option)
- WP Super Cache as full page cache (with Batcache as an alternative)
- PHP 7.x
- Nginx with Apache

## Security Considerations

- Password based logins are disabled.
- Umask 027 or 077.
- ACL integration.
- Credentials-less login for PhpMyAdmin for local network.

## Implementation Details

- Agentless.
- Idempotent.
- Integrated wp-cli.
- Support for version control (git, hg).
- Composer pre-installed.
- Auto-update of almost everything (wp-cli, composer, certbot certs, etc).
- Your own SSL CA.
- PHP-Xdebug pre-installed.

## Roadmap

- Web interface (planned, but no ETA).

## Install procedure

- Rename `.envrc-sample` file as `.envrc` and insert as much information as possible
- Download `bootstrap.sh` and execute it.

```bash
# as root

apt install curl screen -y

# optional steps
# curl -LO https://github.com/pothi/local-dev-box/raw/master/.envrc-sample
cp .envrc-sample .envrc
nano .envrc
# enter at least the following values
# SFTP_USER
# BASE_NAME

# then create the directories and files that are from /etc/skell for the user 'pothi' (or whoever)

# download the bootstrap script
curl -LO https://github.com/pothi/local-dev-box/raw/master/local-dev-box-bootstrap.sh

# please do not trust any script on the internet or github
# so, please go through it!
nano ~/local-bootstrap.sh

# execute it and wait for some time
# screen bash local-dev-box-bootstrap.sh
# or simply
bash local-dev-box-bootstrap.sh

rm local-dev-box-bootstrap.sh

```

## Wiki

For more documentation, supported / tested hosts, todo, etc, please see the [WP-In-A-Box wiki](https://github.com/pothi/wp-in-a-box/wiki).
