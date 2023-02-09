# Local Development Box

Script to quickly install and remove WordPress, PHP and static sites on a local LEMP server.

## Supported Platforms

+ Ubuntu LTS last two versions!

## Generic Goals

* To bootstrap a new WordPress site quickly.
* To remove a new WordPress site.
* To create or remove a new PHP site automatically.

## Performance Checklist

- Redis for object cache (with memcached as an option)
- WP Super Cache as full page cache (with Batcache as an alternative)
- PHP 8.x
- Nginx with Apache

## Security Considerations

- A user needs the following entry in sudoers file... 'user ALL=(ALL) NOPASSWD: /usr/bin/mysql, /usr/sbin/nginx, /usr/bin/systemctl, /usr/bin/ln, /usr/bin/cp, /usr/bin/rm, /usr/bin/sed' (replace user with the actual username)
- A common certificate needs to be present for all local sites already. Recommended to use a real certificate.
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
- Set correct sudo permission ('user ALL=(ALL) NOPASSWD: /usr/bin/mysql, /usr/sbin/nginx, /usr/bin/systemctl, /usr/bin/ln, /usr/bin/cp, /usr/bin/rm, /usr/bin/sed'). Replace user with the actual username.
- Download local-box and try to execute it.

