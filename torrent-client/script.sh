#!/bin/sh

ip=$(ifconfig | grep -A 1 'eth0' | tail -1 | cut -d ':' -f 2 | cut -d ' ' -f 1)
local_if=eth0
tunnel_if=tun0

# Setup firewall
iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -P FORWARD DROP

iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

iptables -A INPUT -p ip -i ${local_if} -s 192.168.201.0/29 -d ${ip} -j ACCEPT
iptables -A OUTPUT -p ip -o ${local_if} -s ${ip} -d 192.168.201.0/29 -j ACCEPT

iptables -A INPUT -p udp -i ${local_if} -d ${ip} --sport 53 -m state --state ESTABLISHED -j ACCEPT
iptables -A OUTPUT -p udp -o ${local_if} -s ${ip} --dport 53 -m state --state NEW,ESTABLISHED -j ACCEPT

iptables -A INPUT -p udp -i ${local_if} --sport ${OPENVPN_PORT} -j ACCEPT
iptables -A OUTPUT -p udp -o ${local_if} --dport ${OPENVPN_PORT} -j ACCEPT

iptables -A INPUT -p tcp -i ${tunnel_if} --dport ${TRANSMISSION_PEER_PORT} -j ACCEPT
iptables -A INPUT -p udp -i ${tunnel_if} --dport ${TRANSMISSION_PEER_PORT} -j ACCEPT
iptables -A OUTPUT -p tcp -o ${tunnel_if} --sport ${TRANSMISSION_PEER_PORT} -j ACCEPT
iptables -A OUTPUT -p udp -o ${tunnel_if} --sport ${TRANSMISSION_PEER_PORT} -j ACCEPT

iptables -A INPUT -p ip -i ${tunnel_if} -m state --state ESTABLISHED -j ACCEPT
iptables -A OUTPUT -p ip -o ${tunnel_if} -m state --state NEW,ESTABLISHED -j ACCEPT

# Setup transmission config
cat transmission.json.template \
	| sed "s/{peer-port}/${TRANSMISSION_PEER_PORT}/g" \
	| sed "s/{rpc-username}/${TRANSMISSION_RPC_USERNAME}/g" \
	| sed "s/{rpc-password}/${TRANSMISSION_RPC_PASSWORD}/g" \
	| sed "s/{rpc-whitelist}/${TRANSMISSION_RPC_WHITELIST}/g" \
        > /config/transmission/settings.json

chown -R transmission:transmission /config/transmission
chmod 750 /config/transmission

# Run transmission under 'transmission' user
sudo -u transmission /usr/bin/transmission-daemon -g /config/transmission -w /data -x /var/run/transmission/daemon.pid

# Run OpenVPN
/usr/sbin/openvpn --config /config/openvpn/${OPENVPN_CONFIG_FILE}
