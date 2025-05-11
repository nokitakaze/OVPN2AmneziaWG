#!/bin/bash
set -e

# deb-src
# In new releases (format *.sources)
if [ -f /etc/apt/sources.list.d/ubuntu.sources ]; then
    sudo sed -i 's/^\(Types:[[:space:]]*\)deb$/\1deb deb-src/' /etc/apt/sources.list.d/ubuntu.sources
# In old releases (classic sources.list)
else
    sudo sed -i 's/^[#[:space:]]*deb-src/deb-src/' /etc/apt/sources.list
fi

# apt add source
sudo apt update --yes
sudo apt install --yes software-properties-common apt-transport-https
sudo add-apt-repository -y ppa:amnezia/ppa

apt update --yes
apt install --yes amneziawg
