#!/bin/sh
# This is the address we assigned to our bridge in /etc/network/interfaces
get_iface_addr(){
	ip -4 addr show $1 | grep -oP '(?<=inet\s)\d+(\.\d+){3}'
}

br_iface="lxc-bridge"
iface="enp0s3"

br_addr=`get_iface_addr $br_iface`
iface_addr=`get_iface_addr $iface`

# Make sure that the IP forwarding is enabled
echo 1 > /proc/sys/net/ipv4/ip_forward

sysctl -w net.ipv4.conf.all.route_localnet=1

# Cleanup the iptables
echo "Cleaning up iptables..."
iptables -F
iptables -F -t nat

echo "Adding LXC rules"
iptables -A FORWARD -i ${br_iface} -s ${br_addr}/24 -m conntrack --ctstate NEW -j ACCEPT
iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A POSTROUTING -t nat -j MASQUERADE

fwd(){
        local src="$1"
        local tgt="$3"
        echo "...forwarding $src to $tgt"
        iptables -t nat -A PREROUTING -i $iface -p tcp --dport $src -j DNAT --to $tgt
        iptables -t nat -A OUTPUT -o lo -d 127.0.0.1 -p tcp --dport $src -j DNAT  --to-destination $tgt
	iptables -t nat -A OUTPUT -d $iface_addr -p tcp --dport $src -j DNAT --to $tgt
}



fwd 80 to 10.0.8.8:80
fwd 5984 to 10.0.8.8:5984
#fwd 22 to 10.0.8.9:22 # assign another port to SSH server for this host machine!

# Testing
# ---------
# Now you should be able to connect `10.0.8.8:443` by connecting `HOST_IP:443`.

