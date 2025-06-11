#!/bin/bash

set -Eeuo pipefail

# Termination signal handler
function shutdown() {
    echo "Termination signal received, exiting..."
    killall sing-box
    exit 0
}

# Subscribe to SIGTERM and SIGINT signals
trap shutdown SIGTERM SIGINT

# Generate a Sing-Box configuration
/app/convert.py

old_ip=$(curl -s 'https://api.ipify.org')
echo "Real IP: $old_ip"
vpn_server_ip=$(/app/get-server-ip.py)
echo "VPN Server IP: $vpn_server_ip"

echo "Start sing-box client"
sing-box run -c /app/sing-config.json &
pid=$!

echo "Process pid: $pid"

# Waiting for the tun0 network interface to become available
while ! ip link show tun0 &>/dev/null; do
    sleep 1
done

###############################
# Get our internal docker ip on eth0 (CIDR)
SUBNET_ETH0=$(ip -o -f inet addr show eth0 | awk '{print $4}')
SUBNET_ETH0_MASK=$(echo "$SUBNET_ETH0" | sed -E 's/^([0-9]+\.[0-9]+\.[0-9]+)\.[0-9]+\/([0-9]+)/\1.0\/\2/')
GATEWAY_ETH0=$(echo "$SUBNET_ETH0" | sed -E 's/^([0-9]+\.[0-9]+\.[0-9]+)\.[0-9]+\/[0-9]+/\1.1/')
echo "on eth0 IP/subnet is $SUBNET_ETH0 with mask $SUBNET_ETH0_MASK and gateway $GATEWAY_ETH0"

SUBNET_TUN0=$(ip -o -f inet addr show tun0 | awk '{print $4}')
SUBNET_TUN0_MASK=$(echo "$SUBNET_TUN0" | sed -E 's/^([0-9]+\.[0-9]+\.[0-9]+)\.[0-9]+\/([0-9]+)/\1.0\/\2/')
GATEWAY_TUN0=$(echo "$SUBNET_TUN0" | sed -E 's/^([0-9]+\.[0-9]+\.[0-9]+)\.[0-9]+\/[0-9]+/\1.1/')
echo "on tun0 IP/subnet is $SUBNET_TUN0 with mask $SUBNET_TUN0_MASK and gateway $GATEWAY_TUN0"

echo "route add $vpn_server_ip gw $GATEWAY_ETH0 dev eth0 metric 0"
route add "$vpn_server_ip" gw "$GATEWAY_ETH0" dev eth0 metric 0
echo "route del default gw $GATEWAY_ETH0 dev eth0"
route del default gw "$GATEWAY_ETH0" dev eth0
echo "route add $GATEWAY_TUN0 dev tun0 metric 0"
route add "$GATEWAY_TUN0" dev tun0 metric 0
echo "route add default gw $GATEWAY_TUN0 dev tun0 metric 1"
route add default gw "$GATEWAY_TUN0" dev tun0 metric 1

# Enable IP forwarding
iptables -t nat -A POSTROUTING -s 172.16.0.0/12 -o tun0 -j MASQUERADE
iptables -A FORWARD -i eth0 -o tun0 -j ACCEPT
iptables -A FORWARD -i tun0 -o eth0 -m state --state RELATED,ESTABLISHED -j ACCEPT

# Show routing
route -n

# Show result
sysctl net.ipv4.ip_forward
iptables -t nat -L -n -v

###############################

# Waiting for a new IP address
while true; do
    # Verifying whether the process is alive
    if ! kill -0 "$pid" 2>/dev/null; then
        echo "Process sing-box (PID $pid) exited"
        exit 1
    fi

    new_ip=$(curl -s 'https://api.ipify.org' || true)

    # new_ip is empty
    if [[ -z "$new_ip" ]]; then
        echo "Received empty IP, retrying in 1 second…"
        sleep 1
        continue
    fi

    # new_ip equals to old_ip
    if [[ "$new_ip" == "$old_ip" ]]; then
        echo "IP hasn't changed, retry in 5 second…"
        sleep 5
        continue
    fi

    # ip changed
    break
done

echo "New IP: $new_ip"
echo "New IP: $new_ip" > /tmp/newip.dat

# Main infinite loop
while true; do
    sleep 3
done
