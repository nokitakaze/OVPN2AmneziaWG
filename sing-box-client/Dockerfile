FROM ghcr.io/sagernet/sing-box:v1.11.13 AS source

# Build finally image
FROM ubuntu:24.04

# copy executable file
COPY --from=source --chown=0:0 --chmod=755 /usr/local/bin/sing-box /usr/local/bin/sing-box

RUN DEBIAN_FRONTEND=noninteractive apt update && \
    DEBIAN_FRONTEND=noninteractive apt install --yes curl python3 iproute2 iptables net-tools

WORKDIR /app
COPY convert.py .
COPY start.sh .
COPY template.json .
COPY get-server-ip.py .

RUN chmod +x /app/*.py /app/*.sh

ENTRYPOINT ["/app/start.sh"]

# for debug purposes only
#RUN DEBIAN_FRONTEND=noninteractive apt update && \
#    DEBIAN_FRONTEND=noninteractive apt install --yes nano screen sudo mc inetutils-ping traceroute htop && \
#    DEBIAN_FRONTEND=noninteractive apt install --yes links elinks lynx
