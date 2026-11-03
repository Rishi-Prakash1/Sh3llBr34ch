#!/bin/bash
set -e

# Start SSH daemon in the foreground (keeps the container alive).
service apache2 start
service vsftpd start 2>/dev/null || true

echo "[*] JANGOW-REMIX lab is up."
echo "[*] Web  : http://localhost:8080/site/"
echo "[*] SSH  : ssh jangow01@localhost -p 2222   (password in .backup leak)"
echo "[*] FTP  : ftp localhost 2121"

exec /usr/sbin/sshd -D
