#!/bin/bash

VIP=$1

apt-get install fail2ban -y
touch /etc/fail2ban/jail.local
cat >/etc/fail2ban/jail.local <<EOF
[sshd]
enabled = true
port = 22,8822
filter = sshd
logpath = /var/log/auth.log
maxretry = 5
findtime = 300
bantime = 3600
ignoreip = 127.0.0.1 $VIP
EOF
systemctl enable fail2ban --now
sleep 10
fail2ban-client status sshd
exit 0