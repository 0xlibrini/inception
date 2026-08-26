#!/bin/bash

while ! mysqladmin ping -h"mariadb" --silent; do
    sleep 1
done

if [ ! -f /var/www/html/wp-config.php ]; then
    wp core download --path=/var/www/html --allow-root

    wp config create \
        --dbname=${MYSQL_DATABASE} \
        --dbuser=${MYSQL_USER} \
        --dbpass=${MYSQL_PASSWORD} \
        --dbhost=mariadb \
        --path=/var/www/html \
        --allow-root

    wp core install \
        --url=${DOMAIN_NAME} \
        --title="Inception" \
        --admin_user=${WP_ADMIN} \
        --admin_password=${WP_ADMIN_PASSWORD} \
        --admin_email=${WP_ADMIN_EMAIL} \
        --path=/var/www/html \
        --allow-root

    wp user create ${WP_USER} ${WP_USER_EMAIL} \
        --role=author \
        --user_pass=${WP_USER_PASSWORD} \
        --path=/var/www/html \
        --allow-root
fi

mkdir -p /run/php

exec php-fpm7.4 -F