#!/bin/sh
# This is the address we assigned to our bridge in /etc/network/interfaces
braddr=10.0.8.1
iface=eth0

# Make sure that the IP forwarding is enabled
echo 1 > /proc/sys/net/ipv4/ip_forward

# Cleanup the iptables
echo "Cleaning up iptables..."
iptables -F
iptables -F -t nat

echo "Adding LXC rules"
iptables -A FORWARD -i lxc-bridge -s ${braddr}/24 -m conntrack --ctstate NEW -j ACCEPT
iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A POSTROUTING -t nat -j MASQUERADE

fwd(){
        local src="$1"
        local tgt="$3"
        echo "...forwarding $src to $tgt"
        iptables -t nat -A PREROUTING -i $iface -p tcp --dport $src -j DNAT --to $tgt
        iptables -t nat -A OUTPUT -o lo -d 127.0.0.1 -p tcp --dport $src -j DNAT  --to-destination $tgt
}

fwd 80 to 10.0.8.8:80
fwd 443 to 10.0.8.8:443
fwd 22 to 10.0.8.9:22 # assign another port to SSH server for this host machine!

# Testing
# ---------
# Now you should be able to connect `10.0.8.8:443` by connecting `HOST_IP:443`.

