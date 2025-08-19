#!/bin/sh

# exiting the script if any command fails
set -e

# [filename] part that is going to be used
FILE=/etc/my.cnf

# using sed: stream editor to find and replace
# as per sed [options] ['command/pattern/replace/flag'] [filename]
sed -i 's/^bind-address\s*=.*/bind-address = 0.0.0.0/' "$FILE"

# start the mariaDB in safe mode and disable netwoking
# running it in the background through usage of &
mariadbd-safe --skip-networking &

# creating a polling logic before the healthcheck
# works until the mariaDB is ready to accept connection
# runs every second till returns 0
until /usr/bin/mariadb-admin ping --silent; do
	sleep 1
done

# creating of actual db and the user through SQL syntax
# most of them are self explanatory through naming
# flushing the privileges mean that changes take effect
mysql -u root <<EOF
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' INDENTIFIED BY '${MYSQL_PASS}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
EOF

# shuts down the mariaDB to restart with all the changes
# afterwards it will run with networking enabled and in foreground
# so it will have the fake PID1 from the container
/usr/bin/mariadb-admin shutdown --socket=/var/run/mysqld/mysqld.sock -u root

# replacing the shell with mysqld process
# making the change into PID1 as per above
exec mysqld