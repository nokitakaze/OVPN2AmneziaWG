#!/bin/bash

# Termination signal handler
function shutdown() {
    echo "Termination signal received, exiting..."
    awg-quick down wg0
    exit 0
}

# Subscribe to SIGTERM and SIGINT signals
trap shutdown SIGTERM SIGINT

# Check whether the Amnezia kernel module is loaded
lsmod | grep -i amnezia

# Generate a WireGuard configuration
# python ~/awg/awgcfg.py --make /etc/amnezia/amneziawg/awg0.conf -i 10.14.88.1/24 -p 49666

old_ip=$(curl -s 'https://api.ipify.org')
echo "Current IP: $old_ip"

# Bring up the WireGuard interface
awg-quick up wg0

new_ip=$(curl -s 'https://api.ipify.org')
echo "New IP: $new_ip"

if [ "$old_ip" == "$new_ip" ]; then
  echo "IP still the same. Exiting"
  awg-quick down wg0
  exit 2
fi

# Enable IP forwarding
iptables -t nat -A POSTROUTING -s 172.21.0.0/16 -o wg0 -j MASQUERADE
iptables -A FORWARD -i eth0 -o wg0 -j ACCEPT
iptables -A FORWARD -i wg0 -o eth0 -m state --state RELATED,ESTABLISHED -j ACCEPT

# Show result
sysctl net.ipv4.ip_forward
iptables -t nat -L -n -v

echo "New IP: $new_ip" > /tmp/newip.dat

# Main infinite loop
while true; do
    sleep 1
done

# Bring down the WireGuard interface (this line will never be reached)
awg-quick down wg0
