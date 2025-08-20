#!/bin/bash

# exit if non 0 value
set -e

# prevents wordpress cli from sending emails
# and adding higher memory limit to PHP
export WP_CLI_DISABLE_MAIL=true
export WP_CLI_PHP_ARGS='-d memory_limit=512M'

# ------------------------------------
# Moving this part inside docker build
# ------------------------------------
# check if wordpress CLI is installed
# if not download, makes executable and moves
# if ! command -v wp > /dev/null; then
# 	curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
# 	chmod +x wp-cli.phar
# 	mv wp-cli.phar /usr/local/bin/wp
# fi
# echo "Did we fail the command -v -> $?"

# ---------------
# DEBUG STATEMENT
# ---------------
ls -la
echo "FIRST LISTING"

# making all the important files readable
cd /var/www/html
chmod -R 755 /var/www/html

# ---------------
# DEBUG STATEMENT
# ---------------
ls -la
echo "SECOND LISTING"

# [file name part just linke in DB setup]
FILE=/etc/php84/php-fpm.d/www.conf

# changing the PHP-FPM socket to use port 9000
sed -i 's|^listen =.*|listen = 9000|' "$FILE"

# ------------------------------------------
# seems like something is wrong at this part
# adding it for testing right now again
# ------------------------------------------
# checking the MariaDB if its ready
# trying up to 10 times every 2 seconds
# most likely to be removed if healthcheck works
for i in {1..10}; do
	if mariadb -h mariadb -p 3306 -u "${MYSQL_USER}" \
		-p"${MYSQL_PASS}" -e "SELECT 1" &>/dev/null; then
		break
	else
		echo "we wait if MariaDB is ready (${i}/10)"
		sleep 2
	fi
done

# checking if the WordPress is present if not download
if [ ! -f index.php ]; then
	echo "Downloading WordPress" && \
	wp core download --allow-root
fi
echo "Was the last command succefull -> $?"

# make a WordPress config file if it doesn't exist
# adding a wraper to try and retry the connection
# before fully exiting the script
for i in {1..10}; do
	if [ ! -f wp-config.php ]; then
		echo "Creating a wp-config file tried ${i}/10"
		if wp config create \
			--dbname="${MYSQL_DATABASE}" \
			--dbuser="${MYSQL_USER}" --dbpass="${MYSQL_PASS}" \
			--dbhost="mariadb:3306" --allow-root; then
			echo "WE DID IT"
			break
		else
			echo "we are retrying the config"
			sleep 2
		fi
	else
		echo "wp-config exists skipping the creation"
		break
	fi
done
echo "Was the last command succefull -> $?"

# install wordpress if its not there
# fillout all of the informations about it
# with supression of warning email not found
# last line would be replacing the --skip-email
if ! wp core is-installed --allow-root; then
	echo "trying to install wordpress and set it up" && \
	wp core install --url="${DOMAIN_NAME}" --title="${WP_TITLE}" \
		--admin_user="${WP_ADMIN}" --admin_password="${WP_ADMIN_PASS}" \
		--admin_email="${WP_ADMIN_EMAIL}" --skip-email --allow-root
		# 2> >(grep -v '/usr/sbin/sendmail: not found' >&2)
fi
echo "Was the last command succefull -> $?"

# create a user if he doesn't exist
if ! wp user get "${WP_USER}" --allow-root &>/dev/null; then
	echo "adding a user to wordpress"
	wp user create "${WP_USER}" "${WP_USER_EMAIL}" \
		--user_pass="${WP_USER_PASS}" --allow-root
fi
echo "Was the last command succefull -> $?"

# setup permissions for the www-data
chown -R www-data:www-data /var/www/html

# -F to run the background and ignore daemonization
exec php-fpm84 -F
