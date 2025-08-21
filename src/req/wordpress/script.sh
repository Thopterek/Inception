#!/bin/bash

# exit if non 0 value
set -e

# prevents wordpress cli from sending emails
export WP_CLI_DISABLE_MAIL=true

# and adding higher memory limit to PHP
# ------------------------------------------
# once again memory problem is not there now
# ------------------------------------------
# export WP_CLI_PHP_ARGS='-d memory_limit=512M'

# ------------------------------------
# Moving this part inside docker build
# ------------------------------------
# check if wordpress CLI is installed
# if not download, makes executable and moves
# ------------------------------------------------------
# And once again back to script no need for optimizaiton
# -------------------------------------
if ! command -v wp > /dev/null; then
	curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
	chmod +x wp-cli.phar
	mv wp-cli.phar /usr/local/bin/wp
fi

# echo "Did we fail the command -v -> $?"

# ---------------
# DEBUG STATEMENT
# ---------------
# ls -la
# echo "FIRST LISTING"

# making all the important files readable
cd /var/www/html
chmod -R 755 /var/www/html

# ---------------
# DEBUG STATEMENT
# ---------------
# ls -la
# echo "SECOND LISTING"

# [file name part just linke in DB setup]
# ---------------------------------------------------
# that could have been a problem with my alpine setup
# the file was there but I changed so much in between
# FILE=/etc/php84/php-fpm.d/www.conf
# --------------------------------------------------
FILE=/etc/php/7.4/fpm/pool.d/www.conf

# changing the PHP-FPM socket to use port 9000
# -------------------------------------------
# this also might need to be changed to
# '36 s|/run/php/php7.4-fpm.sock|9000|'
# ---------------------------------------------
# sed -i 's|^listen =.*|listen = 9000|' "$FILE"
# I did change it to it as per the following
sed -i '36 s|/run/php/php7.4-fpm.sock|9000|' $FILE

echo "---------------------------------------------"
echo "do we get proper user $MYSQL_USER"
echo "and what about password? $MYSQL_PASS"
echo "---------------------------------------------"

# ------------------------------------------
# seems like something is wrong at this part
# adding it for testing right now again
# ------------------------------------------
# checking the MariaDB if its ready
# trying up to 10 times every 2 seconds
# most likely to be removed if healthcheck works
# -------------------------------------------------
# Back at it most likely some alpine specific issue
# for now replaces the healthcheck in compose file
# -------------------------------------------------
for i in $(seq 1 10); do
	if mariadb -h mariadb -P 3306 -u "${MYSQL_USER}" \
		-p"${MYSQL_PASS}" -e "SELECT 1" &>/dev/null; then
		break
	else
		echo "we wait if MariaDB is ready ($i/10)"
		sleep 2
	fi
done

# checking if the WordPress is present if not download
if [ ! -f index.php ]; then
	echo "Downloading WordPress" && \
	wp core download --allow-root
fi

# make a WordPress config file if it doesn't exist
# adding a wraper to try and retry the connection
# before fully exiting the script
# ------------------------------------------
# Going through prior checks we can simplify
# for i in $(seq 1 10); do
# 	if [ ! -f wp-config.php ]; then
# 		echo "Creating a wp-config file tried ${i}/10"
# 		if wp config create \
# 			--dbname="${MYSQL_DATABASE}" \
# 			--dbuser="${MYSQL_USER}" --dbpass="${MYSQL_PASS}" \
# 			--dbhost="mariadb:3306" --allow-root; then
# 			echo "WE DID IT WP CONFIG CREATED"
# 			break
# 		else
# 			echo "we are retrying the config"
# 			sleep 2
# 		fi
# 	else
# 		echo "wp-config exists skipping the creation"
# 		break
# 	fi
# done
# -----------------------
# which I find beautifull
# ------------------------
if [ ! -f wp-config.php ]; then
	wp config create \
	--dbname="${MYSQL_DATABASE}" \
	--dbuser="${MYSQL_USER}" --dbpass="${MYSQL_PASS}" \
	--dbhost="mariadb:3306" --allow-root && \
	echo "WE DID IT WP CONFIG CREATED"
fi

# install wordpress if its not there
# fillout all of the informations about it
# with supression of warning email not found
# last line would be replacing the --skip-email
# --------------------------------------------
# Here things stayed relatively the same
# --------------------------------------
if ! wp core is-installed --allow-root; then
	echo "trying to install wordpress and set it up" && \
	wp core install --url="${DOMAIN_NAME}" --title="${WP_TITLE}" \
		--admin_user="${WP_ADMIN}" --admin_password="${WP_ADMIN_PASS}" \
		--admin_email="${WP_ADMIN_EMAIL}" --skip-email --allow-root
		# 2> >(grep -v '/usr/sbin/sendmail: not found' >&2)
fi

# create a user if he doesn't exist
if ! wp user get "${WP_USER}" --allow-root &>/dev/null; then
	echo "adding a user to wordpress" && \
	wp user create "${WP_USER}" "${WP_USER_EMAIL}" \
		--user_pass="${WP_USER_PASS}" --role=author --allow-root
fi

# setup permissions for the www-data
chown -R www-data:www-data /var/www/html

mkdir -p /run/php

# -F to run the background and ignore daemonization
# ---------------------------------
# one place where alpine is shorter
# ---------------------------------
# exec php-fpm84 -F
exec /usr/sbin/php-fpm7.4 -F