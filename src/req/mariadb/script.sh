#!/bin/sh

# exiting the script if any command fails
set -e

# [filename] part that is going to be used
FILE=/etc/my.cnf

# using sed: stream editor to find and replace
# as per sed [options] ['command/pattern/replace/flag'] [filename]
sed -i 's/^bind-address\s*=.*/bind-address = 0.0.0.0/' "$FILE"

cat /etc/my.cnf
echo "was it huge?"

# ------------------
# DISABLED FOR DEBUG
# just mariadb-safe
# ------------------
# start the mariaDB in safe mode and disable netwoking
# running it in the background through usage of &
# mariadbd-safe --skip-networking &
mariadbd-safe --datadir=/var/lib/mysql &
echo "MariaDB started -> mariadbd-safe exit value -> $?"

# creating a polling logic before the healthcheck
# works until the mariaDB is ready to accept connection
# runs every second till returns 0
until /usr/bin/mariadb-admin ping --silent; do
	echo "WE ARE PINGING" && \
	sleep 1
done
echo "after the pinging exit value -> $?"

# creating of actual db and the user through SQL syntax
# most of them are self explanatory through naming
# flushing the privileges mean that changes take effect
mysql -u root <<EOF
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASS}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
EOF
echo "what about mysql -u root exit value $?"

# shuts down the mariaDB to restart with all the changes
# afterwards it will run with networking enabled and in foreground
# so it will have the fake PID1 from the container
/usr/bin/mariadb-admin shutdown --socket=/var/run/mysqld/mysqld.sock -u root
echo "how is the shutdown going exit value $?"

# replacing the shell with mysqld process
# making the change into PID1 as per above
exec mysqld