#!/bin/bash
set -e

# Esperar a que el contenedor de MariaDB esté arriba y acepte conexiones
echo "[-] Esperando a que MariaDB en mariadb:3306 esté lista..."
until mysqladmin ping -h"mariadb" --silent; do
    sleep 2
done
echo "[+] ¡MariaDB detectada con éxito!"

# Si WordPress no está descargado en el volumen persistente, lo instalamos
if [ ! -f "wp-config.php" ]; then
    echo "[-] Descargando WordPress..."
    wp core download --allow-root

    echo "[-] Creando archivo wp-config.php..."
    wp config create \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="${MYSQL_PASSWORD}" \
        --dbhost="mariadb:3306" \
        --allow-root

    echo "[-] Instalando WordPress y configurando Administrador..."
    wp core install \
        --url="${DOMAIN_NAME}" \
        --title="${WP_TITLE}" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --allow-root

    echo "[-] Creando usuario secundario..."
    wp user create \
        "${WP_USER}" \
        "${WP_USER_EMAIL}" \
        --user_pass="${WP_USER_PASSWORD}" \
        --role=author \
        --allow-root
    
    # Dar permisos correctos al servidor web sobre los archivos de WordPress
    chown -R www-data:www-data /var/www/wordpress
    echo "[+] ¡WordPress configurado exitosamente!"
fi

# Ejecutar PHP-FPM en primer plano (-F) para mantener el contenedor vivo
echo "[-] Iniciando PHP-FPM..."
exec php-fpm7.4 -F