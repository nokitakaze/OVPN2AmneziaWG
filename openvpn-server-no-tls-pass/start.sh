#!/bin/bash
source ./functions.sh

old_ip=$(curl -s 'https://api.ipify.org')
echo "Old external IP: $old_ip"

# Get IP of AmneziaWG Client host
GW_IP=$(getent hosts amneziawg_client | awk '{ print $1 }')

echo "AmneziaWG Client Host: $GW_IP"

# Get our internal docker ip on eth0 (CIDR)
SUBNET=$(ip -o -f inet addr show eth0 | awk '{print $4}')
SUBNET_MASK=$(echo "$SUBNET" | sed -E 's/^([0-9]+\.[0-9]+\.[0-9]+)\.[0-9]+\/([0-9]+)/\1.0\/\2/')

echo "on eth0 IP/subnet is $SUBNET with mask $SUBNET_MASK"

# Get our internal docker gateway
GATEWAY=$(echo "$SUBNET" | sed -E 's/^([0-9]+\.[0-9]+\.[0-9]+)\.[0-9]+\/[0-9]+/\1.1/')

echo "ip route add \"$SUBNET_MASK\" via \"$GATEWAY\""

# Add internal docker net
ip route add "$SUBNET_MASK" via "$GATEWAY"

echo "ip route add 192.168.0.0/16 via \"$GATEWAY\" dev eth0"
ip route add 192.168.0.0/16 via "$GATEWAY" dev eth0

# Delete current default route
ip route del default

# Add new default route via AmneziaWG
ip route add default via "$GW_IP" metric 1

# Show routing
route -n

while true; do
    new_ip=$(curl -s 'https://api.ipify.org')
    if [[ -z "$new_ip" ]]; then
        echo "Error: unable to retrieve external IP"
        sleep 5
    else
        echo "New external IP: $new_ip"
        break
    fi
done

# Start service
echo "Start OpenVPN Server itself"
SHORT=rnqs
LONG="regenerate,noop,quit,skip"
OPTS=$(getopt -a -n dockovpn --options $SHORT --longoptions $LONG -- "$@")

if [[ $? -ne 0 ]] ; then
    exit 1
fi

eval set -- "$OPTS"

while :
do
  case "$1" in
    -r | --regenerate)
      REGENERATE="1"
      shift;
      ;;
    -n | --noop)
      NOOP="1"
      shift;
      ;;
    -q | --quit)
      QUIT="1"
      shift;
      ;;
    -s | --skip)
      SKIP="1"
      shift;
      ;;
    --)
      shift;
      break
      ;;
    *)
      echo "Unexpected option: $1"
      exit 1
      ;;
  esac
done

ADAPTER="${NET_ADAPTER:=eth0}"

mkdir -p /dev/net

if [ ! -c /dev/net/tun ]; then
    echo "$(datef) Creating tun/tap device."
    mknod /dev/net/tun c 10 200
fi

# Allow UDP traffic on port 1196.
iptables -A INPUT -i $ADAPTER -p udp -m state --state NEW,ESTABLISHED --dport 1196 -j ACCEPT
iptables -A OUTPUT -o $ADAPTER -p udp -m state --state ESTABLISHED --sport 1196 -j ACCEPT

# Allow traffic on the TUN interface.
iptables -A INPUT -i tun0 -j ACCEPT
iptables -A FORWARD -i tun0 -j ACCEPT
iptables -A OUTPUT -o tun0 -j ACCEPT

# Allow forwarding traffic only from the VPN.
iptables -A FORWARD -i tun0 -o $ADAPTER -s 10.8.0.0/24 -j ACCEPT
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o $ADAPTER -j MASQUERADE

cd "$APP_PERSIST_DIR"

LOCKFILE=.gen

# Regenerate certs only on the first start
if [ ! -f $LOCKFILE ]; then
    IS_INITIAL="1"
    test -d pki || REGENERATE="1"
    if [[ -n $REGENERATE ]]; then
        easyrsa --batch init-pki
        easyrsa --batch gen-dh
        # DH parameters of size 2048 created at /usr/share/easy-rsa/pki/dh.pem
        # Copy DH file
        cp pki/dh.pem /etc/openvpn
    fi

    easyrsa build-ca nopass << EOF

EOF
    # CA creation complete and you may now import and sign cert requests.
    # Your new CA certificate file for publishing is at:
    # /opt/Dockovpn_data/pki/ca.crt

    easyrsa gen-req MyReq nopass << EOF2

EOF2
    # Keypair and certificate request completed. Your files are:
    # req: /opt/Dockovpn_data/pki/reqs/MyReq.req
    # key: /opt/Dockovpn_data/pki/private/MyReq.key

    easyrsa sign-req server MyReq << EOF3
yes
EOF3
    # Certificate created at: /opt/Dockovpn_data/pki/issued/MyReq.crt

    openvpn --genkey --secret ta.key << EOF4
yes
EOF4

    easyrsa --days=$CRL_DAYS gen-crl

    touch $LOCKFILE
fi

# Copy server keys and certificates
cp pki/dh.pem pki/ca.crt pki/issued/MyReq.crt pki/private/MyReq.key pki/crl.pem ta.key /etc/openvpn

cd "$APP_INSTALL_PATH"

# Print app version
getVersionFull

if ! [[ -n $NOOP ]]; then
    # Need to feed key password
    openvpn --config /etc/openvpn/server.conf &

    sleep 5
    route -n

    if [[ -n $IS_INITIAL ]]; then
        # By some strange reason we need to do echo command to get to the next command
        echo " "

        if ! [[ -n $SKIP ]]; then
          # Generate client config
          generateClientConfig $@ &
        else
          echo "$(datef) SKIP is set: skipping client generation"
        fi
    else
      echo "$(datef) Data exist: skipping client generation"
    fi
fi

if ! [[ -n $QUIT ]]; then
    tail -f /dev/null
fi
