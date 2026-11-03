#!/bin/bash
# Runs at BUILD time inside the image. Creates users, flags, sudo rule,
# shadow-backup exposure, and the web entry point.
set -e

############################################
# 1. Users
############################################
# jangow01 : stage-1 SSH user (creds leaked via web .backup)
useradd -m -s /bin/bash jangow01
echo 'jangow01:abygurl69' | chpasswd

# butcher : second user, hash crackable (microphone is in rockyou)
useradd -m -s /bin/bash butcher
echo 'butcher:microphone' | chpasswd

############################################
# 2. Flags  (owner-only, 0400, dirs locked 0700)
############################################
# -- jangow01 flag
echo 'HEHE{sudo_wont_save_you_this_time}' > /home/jangow01/user.txt
chown jangow01:jangow01 /home/jangow01/user.txt
chmod 0400 /home/jangow01/user.txt
chmod 0750 /home/jangow01

# -- butcher flag  (0700 home so jangow01 cannot cd/cat into it)
echo 'ROOTLESS{1_4m_1n}' > /home/butcher/user2.txt
chown butcher:butcher /home/butcher/user2.txt
chmod 0400 /home/butcher/user2.txt
chmod 0700 /home/butcher

# -- root flag
echo 'ROOTED{n0w_1_4m_g0d}' > /root/proof.txt
chown root:root /root/proof.txt
chmod 0400 /root/proof.txt

############################################
# 3. Stage-1 enumeration: readable shadow backup  (option b)
############################################
# A realistic admin mistake: a world-readable backup of the shadow file
# in /var/backups. Real /etc/shadow stays 0640 root:shadow (unreadable),
# so jangow01 must FIND the backup to pull butcher's hash.
cp /etc/shadow /var/backups/shadow.bak
chmod 0644 /var/backups/shadow.bak
cp /etc/passwd /var/backups/passwd.bak
chmod 0644 /var/backups/passwd.bak

############################################
# 4. Privesc: butcher can run awk as root, no password
############################################
echo 'butcher ALL=(root) NOPASSWD: /usr/bin/awk' > /etc/sudoers.d/butcher
chmod 0440 /etc/sudoers.d/butcher

############################################
# 5. Web root  (the site the user submitted + command injection)
############################################
rm -f /var/www/html/index.html
cp -r /tmp/site /var/www/html/site
chown -R www-data:www-data /var/www/html/site
# make the leak readable by the webserver (so connection.php?cmd=cat can read it)
chmod 0644 /var/www/html/site/.backup
# landing redirect: / -> /site/
cat > /var/www/html/index.html <<'EOF'
<!DOCTYPE html><html><head><meta http-equiv="refresh" content="0;url=/site/"></head><body></body></html>
EOF
chown www-data:www-data /var/www/html/index.html

############################################
# 6. FTP for jangow01 (matches original box flavour)
############################################
mkdir -p /var/run/vsftpd/empty

echo "[build] users, flags, sudo rule, shadow backup and webroot configured."
