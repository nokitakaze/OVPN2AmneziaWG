#!/bin/sh

sudo modprobe amneziawg
sudo sysctl -q net.ipv4.ip_forward=1

# The command sets the kernel parameter net.ipv4.conf.all.src_valid_mark, allowing the kernel to rely on fwmark
# when verifying the source address of a packet; this is necessary for proper operation of policy routing and VRF,
# when the source may not belong to the outgoing interface
sudo sysctl -q net.ipv4.conf.all.src_valid_mark=1

docker-compose down
docker-compose up -d
