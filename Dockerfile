FROM ubuntu:20.04

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        apache2 libapache2-mod-php php php-mysqli \
        openssh-server vsftpd sudo nano less ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# ---- SSH hardening for a lab: password auth on, no root login ----
RUN mkdir -p /var/run/sshd && \
    sed -i 's/#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config && \
    sed -i 's/#\?PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config

# ---- FTP config ----
COPY vsftpd.conf /etc/vsftpd.conf

# ---- site files the user submitted (staged, then setup script places them) ----
COPY site/ /tmp/site/

# ---- build-time setup: users, flags, sudo, shadow backup, webroot ----
COPY setup-users.sh /tmp/setup-users.sh
RUN chmod +x /tmp/setup-users.sh && /tmp/setup-users.sh && rm /tmp/setup-users.sh

# ---- runtime ----
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 22 80 21
ENTRYPOINT ["/entrypoint.sh"]
