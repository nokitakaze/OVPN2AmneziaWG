FROM ubuntu:24.04

RUN sed -i 's/^\(Types: *\)deb$/\1deb deb-src/' /etc/apt/sources.list.d/ubuntu.sources && \
    DEBIAN_FRONTEND=noninteractive apt update && \
    DEBIAN_FRONTEND=noninteractive apt install -y bash sudo build-essential software-properties-common apt-transport-https curl gnupg2 ca-certificates lsb-release dirmngr python3-pip python-dev-is-python3 python3-setuptools python3-virtualenv && \
    add-apt-repository -y ppa:amnezia/ppa && \
    DEBIAN_FRONTEND=noninteractive apt update && \
    DEBIAN_FRONTEND=noninteractive apt install -y curl wget python3 python3-pip python3-qrcode iptables iproute2 net-tools

RUN DEBIAN_FRONTEND=noninteractive apt install -y amneziawg=1.0.20210914-0~202410011337+c0b400c~ubuntu24.04.1

RUN mkdir /root/awg

WORKDIR /root/awg

#RUN DEBIAN_FRONTEND=noninteractive apt install --yes curl wget python3 python3-pip python3-qrcode iptables iproute2 net-tools && \
#    echo "net.ipv4.ip_forward = 1" > /etc/sysctl.d/00-amnezia.conf && \
#    wget 'https://gist.githubusercontent.com/remittor/8c3d9ff293b2ba4b13c367cc1a69f9eb/raw/awgcfg.py' -O ~/awg/awgcfg.py

# for debug purposes only
RUN DEBIAN_FRONTEND=noninteractive apt install --yes nano screen sudo mc inetutils-ping traceroute htop

# awg-quick without resolvconv
COPY awg-quick /usr/bin/

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /usr/bin/awg-quick /entrypoint.sh

CMD ["/entrypoint.sh"]
