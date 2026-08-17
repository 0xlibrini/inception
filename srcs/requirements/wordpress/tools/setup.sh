#!/bin/bash
set -e

DB_PASSWORD=$(cat /run/secrets/db_password)

until mysqladmin ping -h mariadb -u"${MYSQL_USER}" -p"${DB_PASSWORD}" --silent; do
    echo "Waiting for MariaDB..."
    sleep 2
done

if [ ! -f "wp-config.php" ]; then
    wp core download --allow-root
    wp config create \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="${DB_PASSWORD}" \
        --dbhost=mariadb \
        --allow-root
    wp core install \
        --url="${DOMAIN_NAME}" \
        --title="Inception" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --allow-root
fi

exec php-fpm7.4 -F