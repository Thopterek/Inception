#!/bin/bash

# exit != 0 -> stop
set -e

# directory used for the key and chain
mkdir -p /etc/nginx/ssl

# generating a self-signed SSL certificate
# no passphrase on the private key and save it
# same thing to save certificate and add details
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
	-keyout /etc/nginx/ssl/key.pem -out /etc/nginx/ssl/fullchain.pem \
	-subj "/C=DE/ST=BW/L=Heilbronn/O=42/OU=student/CN="${DOMAIN_NAME}""

# creating or overwriting the the nginx config
# setting up the listening port to 443
# getting request from www and other one
# specifies the certificate and keys to use
# forces to use TLS 1.3 passed to wordpress server
cat > /etc/nginx/sites-available/default <<EOF
server {
	listen 443 ssl;
	server_name "${DOMAIN_NAME}" www.${DOMAIN_NAME};
	root /var/www/html;
	index index.php;
	ssl_certificate /etc/nginx/ssl/fullchain.pem;
	ssl_certificate_key /etc/nginx/ssl/key.pem;
	ssl_protocols TLSv1.3;
	location ~ \.php$ {
		include snippets/fastcgi-php.conf;
		fastcgi_pass wordpress:9000;
	}
}
EOF

# create a smybolic link (shortcut to another file)
# -sf overwrites the link if needed
ln -sf "/etc/nginx/sites-available/default" "/etc/nginx/sites-enabled/default"

# a safety test before starting nginx
nginx -t

# start in the foreground to be a main process
exec nginx -g "daemon off;"