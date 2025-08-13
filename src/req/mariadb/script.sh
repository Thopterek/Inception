#!/bin/sh

# -------------------------------------------------------
# I base whole thing on mariadb mysql_secure_installation
# -------------------------------------------------------
config="./my.cnf"
rootpass=${DB_PASS}

do_query() {
	echo "$1" > $command
}

do_query "DELETE FROM mysql.user WHERE User='';"
if [ $? -eq 0 ]; then
echo "We removed anon users"
else
echo "Error: removing of anon users failed"