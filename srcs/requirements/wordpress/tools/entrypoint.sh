#!/bin/bash
set -e

echo "[-] Waiting for MariaDB on mariadb:3306 to be ready..."
until mysqladmin ping -h"mariadb" --silent; do
    sleep 2
done
echo "[+] MariaDB has been successfully detected!"

mkdir -p /var/www/wordpress
cd /var/www/wordpress

mkdir -p /run/php
sed -i 's|listen = /run/php/php8.2-fpm.sock|listen = 9000|g' /etc/php/8.2/fpm/pool.d/www.conf

if [ ! -f "wp-config.php" ]; then
    echo "[-] Downloading Wordpress..."
    wp core download --allow-root --force

    echo "[-] Creating the wp-config.php file..."
    wp config create \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="$(cat /run/secrets/mysql_password)" \
        --dbhost="mariadb:3306" \
        --allow-root

    echo "[-] Installing WordPress and setting up the admin panel..."
    wp core install --allow-root \
        --url="${DOMAIN_NAME}" \
        --title="${WP_TITLE}" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="$(cat /run/secrets/wp_admin_password)" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --skip-email

    echo "[-] Creating a secondary user..."
    wp user create \
        "${WP_USER}" \
        "${WP_USER_EMAIL}" \
        --user_pass="$(cat /run/secrets/wp_user_password)" \
        --role=author \
        --allow-root
    
    chown -R www-data:www-data /var/www/wordpress
    echo "[+] WordPress has been successfully set up!"
fi

REDIS_MARKER="/var/www/wordpress/.redis_configured"

if [ ! -f "$REDIS_MARKER" ]; then
  echo "[WP] Setting up Redis cache..."
  wp plugin install redis-cache --activate --path=/var/www/wordpress --allow-root || true
  wp config set WP_REDIS_HOST redis --type=constant --path=/var/www/wordpress --allow-root
  wp config set WP_REDIS_PORT 6379 --raw --type=constant --path=/var/www/wordpress --allow-root
  wp redis enable --path=/var/www/wordpress --allow-root || true
  touch "$REDIS_MARKER"
  chown www-data:www-data "$REDIS_MARKER"
fi

cd /var/www/wordpress

echo "[-] Init PHP-FPM 8.2..."
exec php-fpm8.2 -F