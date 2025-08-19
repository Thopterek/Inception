#!/bin/bash

# exit if non 0 value
set -e

# prevents wordpress cli from sending emails
export WP_CLI_DISABLE_MAIL=true

# check if wordpress CLI is installed
# if not download, makes executable and moves
if ! command -v wp > /dev/null; then
	curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
	chmod +x wp-cli.phar
	mv wp-cli.phar /usr/local/bin/wp
fi

# making all the important files readable
cd /var/www/html
chmod -R 755 /var/www/html

# [file name part just linke in DB setup]
FILE=/etc/php84/php-fpm.d/www.conf

# changing the PHP-FPM socket to use port 9000
sed -i 's|^listen =.*|listen = 9000|' "$FILE"

# ------------------------------------------
# seems like something is wrong at this part
# ------------------------------------------
# checking the MariaDB if its ready
# trying up to 10 times every 2 seconds
# most likely to be removed if healthcheck works
# for i in {1..10}; do
# 	if mariadb -h mariadb -P 3306 -u "${MYSQL_USER}" \
# 		-p"${MYSQL_PASS}" -e "SELECT 1" &>/dev/null; then
# 		break
# 	else
# 		echo "we wait if MariaDB is ready (${i}/10)"
# 		sleep 2
# 	fi
# done

# checking if the WordPress is present if not download
if [ ! -f index.php ]; then
	wp core download --allow-root
fi

# values to be filled out in the config file
VALUES="--dbname="${MYSQL_DATABASE}" --dbuser="${MYSQL_USER}" --dbpass="${MYSQL_PASS}""

# make a WordPress config file if it doesn't exist
if [ ! -f wp-config.php ]; then
	wp config create "$VALUES" --dbhost="mariadb:3306" --allow-root
fi

# install wordpress if its not there
# fillout all of the informations about it
# with supression of warning email not found
# last line would be replacing the --skip-email
if ! wp core is-installed --allow-root; then
	wp core install --url="${DOMAIN_NAME}" --title="${WP_TITLE}" \
		--admin_user="${WP_ADMIN}" --admin_password="${WP_ADMIN_PASS}" \
		--admin_email="${WP_ADMIN_EMAIL}" --skip-email --allow-root
		# 2> >(grep -v '/usr/sbin/sendmail: not found' >&2)
fi

# create a user if he doesn't exist
if ! wp user get "${WP_USER}" --allow-root &>/dev/null; then
	wp user create "${WP_USER}" "${WP_USER_EMAIL}" \
		--user_pass="${WP_USER_PASS}" --allow-root
fi

# setup permissions for the www-data
chown -R www-data:www-data /var/www/html

# -F to run the background and ignore daemonization
exec php-fpm84 -F
