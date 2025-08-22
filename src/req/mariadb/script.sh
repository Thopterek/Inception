#!/bin/sh

# exiting the script if any command fails
set -e

# -------------------------------
# Seems to be not needed for now
# ------------------------------
# extra part for permissions
# adding daemon run ones
# if [ ! -d "/run/mysqld" ]; then
# 	mkdir -p /run/mysqld
# 	chown -R mysql:mysql /run/mysqld
# fi

# --------------------------------------------
# Old file path used before changing to Debian
# with below one that is about the new one
# --------------------------------------------
# [filename] part that is going to be used
# FILE=/etc/my.cnf
FILE=/etc/mysql/mariadb.conf.d/50-server.cnf


# using sed: stream editor to find and replace
# as per sed [options] ['command/pattern/replace/flag'] [filename]
sed -i 's/^bind-address\s*=.*/bind-address = 0.0.0.0/' "$FILE"

cat $FILE
echo "was it huge?"

# -------------------
# DISABLED FOR DEBUG
# just mariadb-safe
# replaced with mysql
# -------------------
# start the mariaDB in safe mode and disable netwoking
# running it in the background through usage of &
# with an extra check beforehand
# mariadbd-safe --skip-networking &
#mariadbd-safe --datadir=/var/lib/mysql &
#echo "MariaDB started -> mariadbd-safe exit value -> $?"
# -------------------------------------------------------
# This part generally seems to be not needed as for now
# because of the change to the Debian version
# ------------------------------------------------------
#if [ ! -d "/var/lib/mysql/mysql" ]; then
#	echo "MARIADB GETTING INSTALED"
#	mysql_install_db --user=mysql --datadir=/var/lib/mysql --rpm
#fi

# -------------------------------------------
# Same part replacments back mysqld_safe
# easier with debian 
# the alpine thing is left to show the pain
# ------------------------------------------
#echo "once again background running MariaDB"
# mysqld is going oooout
#/usr/bin/mariadbd --user=mysql --skip-networking &
#echo "successfull mysqld? -> $?"
#MYSQL_PID=$!
mysqld_safe --skip-networking &

# creating a polling logic before the healthcheck
# works until the mariaDB is ready to accept connection
# runs every second till returns 0
# -------------------------------------------------------------
# Replacing the: until /usr/bin/mariadb-admin ping --silent; do
# with the simpler version for the Debian which is below
# -------------------------------------------------------------
until mysqladmin ping --silent; do
	echo "WE ARE PINGING"
	sleep 1
done

echo "we want to use database name -> $MYSQL_DATABASE"
echo "user -> $MYSQL_USER with password -> $MYSQL_PASS"
echo "then grant all privilages to him"

# creating of actual db and the user through SQL syntax
# most of them are self explanatory through naming
# flushing the privileges mean that changes take effect
mysql -u root <<EOF
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MARIADB_ROOT_PASSWORD}';
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASS}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
EOF

# echo "what about mysql -u root exit value $?"

# shuts down the mariaDB to restart with all the changes
# afterwards it will run with networking enabled and in foreground
# so it will have the fake PID1 from the container
# ------------------------------------------------------
# once again simpler version is possible thankfully
# rather than -> /usr/bin/mariadb-admin we got below one
# ------------------------------------------------------ 
mysqladmin shutdown --socket=/var/run/mysqld/mysqld.sock -u root -p${MARIADB_ROOT_PASSWORD}

# DEBUG FOR FINISHING THE MARIADB SETUP
echo "---------------------------------------"
echo "MARIADB FINISHED SETTING UP: LETS GOOO"
echo "---------------------------------------"

# replacing the shell with mysqld process
# making the change into PID1 as per above
# ---------------------------------------
# no need for option --user=mysql
# the Debian supremacy for use is clear
# --------------------------------------
exec mysqld
