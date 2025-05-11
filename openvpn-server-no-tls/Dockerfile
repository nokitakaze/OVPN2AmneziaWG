FROM alekslitvinenk/openvpn:v1.14.0

COPY functions.sh /opt/Dockovpn/functions.sh
COPY start.sh /opt/Dockovpn/start.sh
COPY server.conf /etc/openvpn/server.conf
RUN chmod +x /opt/Dockovpn/start.sh

# for debug purposes only
# RUN apk update && apk add nano screen sudo mc htop curl
