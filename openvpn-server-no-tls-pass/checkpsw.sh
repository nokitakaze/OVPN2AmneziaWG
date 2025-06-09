#!/usr/bin/env bash
PASSFILE="/etc/openvpn/psw-file"
LOG="/var/log/openvpn-auth.log"

read_creds() {                    # OpenVPN sends login and password via environment variables
    USERNAME="$username"
    PASSWORD="$password"
}

read_creds
if grep -qE "^${USERNAME}:${PASSWORD}$" "$PASSFILE"; then
    echo "$(date +'%F %T') OK  $USERNAME"  >> "$LOG"
    exit 0
else
    echo "$(date +'%F %T') ERR $USERNAME"  >> "$LOG"
    exit 1
fi
