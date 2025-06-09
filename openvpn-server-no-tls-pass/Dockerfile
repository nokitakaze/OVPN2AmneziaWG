FROM alekslitvinenk/openvpn:v1.14.0

COPY functions.sh /opt/Dockovpn/functions.sh
COPY start.sh /opt/Dockovpn/start.sh
COPY server.conf /etc/openvpn/server.conf
COPY checkpsw.sh /etc/openvpn/checkpsw.sh
RUN chmod +x /opt/Dockovpn/start.sh /etc/openvpn/checkpsw.sh && \
    touch /etc/openvpn/psw-file

# for debug purposes only
# RUN apk update && apk add nano screen sudo mc htop curl
