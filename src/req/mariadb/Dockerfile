# ------------------
# TESTING MY DUDES
# ----------------

FROM	alpine:3.21

# Install MariaDB
RUN		apk update && apk upgrade &&\
		apk add mariadb mariadb-client

# Copy MariaDB configuration files
COPY	./new_script.sh /tmp/configure-mariadb.sh
RUN		chmod +x /tmp/configure-mariadb.sh

# Run MariaDB configuration script as entry point
ENTRYPOINT	[ "sh", "/tmp/configure-mariadb.sh" ]