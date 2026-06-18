#!/bin/sh

mkdir -p /var/run/vsftpd/empty

if ! id "$FTP_USER" >/dev/null 2>&1; then
    useradd -m -s /bin/bash "$FTP_USER"
    echo "$FTP_USER:$FTP_PASSWORD" | chpasswd
    
    usermod -d /var/www/wordpress "$FTP_USER"
    chown -R "$FTP_USER:$FTP_USER" /var/www/wordpress
fi

cat << EOF > /etc/vsftpd.conf
listen=YES
local_enable=YES
write_enable=YES
local_umask=022
dirmessage_enable=YES
use_localtime=YES
xferlog_enable=YES
connect_from_port_20=YES
chroot_local_user=YES
secure_chroot_dir=/var/run/vsftpd/empty
pasv_enable=YES
pasv_min_port=40000
pasv_max_port=40005
pasv_address=127.0.0.1
allow_writeable_chroot=YES
EOF

echo "[+] Servidor FTP levantado para el usuario $FTP_USER..."
exec vsftpd /etc/vsftpd.conf