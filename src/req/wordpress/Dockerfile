# ---------------------------------
# TESTING IF IT RUNS BETTER
# --------------------------------
FROM	alpine:3.21

# Install PHP 8.1 & MariaDB-client dependencies
RUN		apk update && apk upgrade &&\
		apk add php84 php84-fpm php84-bcmath php84-bz2 php84-calendar php84-cli php84-ctype \
			php84-curl php84-dom php84-exif php84-fileinfo php84-gd php84-gmp \
			php84-iconv php84-imap php84-intl php84-json php84-mbstring \
			php84-mysqli php84-mysqlnd php84-openssl php84-pcntl php84-pdo php84-pdo_mysql \
			php84-pdo_pgsql php84-pdo_sqlite php84-pgsql php84-phar php84-posix php84-session \
			php84-shmop php84-simplexml php84-soap php84-sockets php84-sodium php84-sqlite3 \
			php84-sysvsem php84-sysvshm php84-tokenizer php84-xml php84-xmlreader php84-xmlwriter \
			php84-xsl php84-zip php84-zlib &&\
		apk add mariadb-client

# Configure PHP-fpm to listen on internal inception network port 9000
RUN		sed -i 's/listen = 127.0.0.1:9000/listen = 9000/g' /etc/php84/php-fpm.d/www.conf

RUN ln -s /usr/bin/php84 /usr/bin/php

# Install WP-CLI
#	Moving wp-cli.phar to /usr/bin/wp-cli.phar rather than /usr/bin/wp to avoid
#	PHP errors for phar vendors files missing. This is a wp-cli bug:
#		https://github.com/wp-cli/config-command/issues/141
#		https://github.com/wp-cli/config-command/issues/31
#		https://github.com/wp-cli/wp-cli/issues/4689#issuecomment-366428642
RUN		apk add curl &&\
		curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar &&\
		chmod +x wp-cli.phar &&\
		mv wp-cli.phar /usr/bin/wp-cli.phar

# Copy WordPress configuration file
COPY	./new_script.sh /tmp/configure-wordpress.sh
RUN		chmod +x /tmp/configure-wordpress.sh

RUN mkdir -p /var/www/html/wordpress
WORKDIR /var/www/html/wordpress

# Run the WordPress configuration file at container startup
ENTRYPOINT	[ "sh", "/tmp/configure-wordpress.sh" ]