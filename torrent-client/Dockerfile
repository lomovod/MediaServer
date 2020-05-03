FROM alpine:3.11

VOLUME /config/openvpn
VOLUME /config/transmission
VOLUME /data

RUN apk --no-cache add bash iptables ip6tables openvpn transmission-daemon sudo \
    && mkdir -p /dev/net \
    && mknod -m 0666 /dev/net/tun c 10 200 

WORKDIR /root

COPY script.sh .
COPY transmission.json.template .

EXPOSE 9091

CMD /root/script.sh