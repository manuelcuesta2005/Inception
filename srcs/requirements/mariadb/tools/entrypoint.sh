#!/bin/bash
set -e

mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld
chown -R mysql:mysql /var/lib/mysql

if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "[-] Initialising MariaDB’s internal structure..."
    mysql_install_db --user=mysql --datadir=/var/lib/mysql > /dev/null
fi

if [ ! -d "/var/lib/mysql/${MYSQL_DATABASE}" ]; then
    echo "[-] Initialising the system database..."

    mysqld --user=mysql --skip-networking &
    pid="$!"

    until mysqladmin ping --silent; do
        echo "[...] waiting for mariadb..."
        sleep 1
    done

    echo "[-] Create Database and users..."
    mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';"
    
    mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;"
    mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';"
    mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';"
    mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "FLUSH PRIVILEGES;"

    echo "[-] Shutting down the temporary server..."
    mysqladmin -u root -p"${MYSQL_ROOT_PASSWORD}" shutdown
    wait "$pid"
    echo "[-] ¡Database successfully configured!"
fi

exec mysqld --user=mysql