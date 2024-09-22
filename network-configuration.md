# Description 

There are 2 types of network connection: 

1. NAT configuration: Container will be behind a NAT firewall. Easier to maintain.
2. Bridge configuration: Container will be able to directly access host network.

# NAT Configuration

> Container will have the IP: `10.0.8.8` and its gateway will be: `10.0.8.1`

1. Add the following settings to the `/var/lib/lxc/your-container/config`: 

```
lxc.net.0.ipv4.address = 10.0.8.8
lxc.net.0.ipv4.gateway = 10.0.8.1
lxc.net.0.type = veth
lxc.net.0.link = lxc-bridge
lxc.net.0.flags = up
```

2. Declare `lxc-bridge` in `/etc/network/interfaces` file: 

```
auto lxc-bridge
iface lxc-bridge inet static
    bridge_ports none
    bridge_fd 0
    address 10.0.8.1
    netmask 255.255.0.0
    up /etc/network/lxc-nat-setup.sh 
```

3. Create `/etc/network/lxc-nat-setup.sh` (unless you use `iptables-persistent` or something like that):


```bash
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
iptables -A FORWARD -i lxc-bridge -s ${braddr}/24 -m conntrack --ctstate NEW -jACCEPT
iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A POSTROUTING -t nat -j MASQUERADE

# Port forwarding (optional)
# --------------------------
fwd(){
        local src="$1"
        local tgt="$3"
        echo "...forwarding $src to $tgt"
        iptables -t nat -A PREROUTING -i $iface -p tcp --dport $src -j DNAT --to $tgt
        iptables -t nat -A OUTPUT -o lo -d 127.0.0.1 -p tcp --dport $src -j DNAT  --to-destination $tgt
}

# couchdb
#fwd 5984 to 10.0.8.87:5984

```

Make sure that this script is executable:

```bash
chmod +x /etc/network/lxc-nat-setup.sh
```

4. Apply this step only for VMs which are the clone of the Host itself: If you clone host machine itself (with `snapshot-lxc / my-vm` command) you should remove any LXC specific entry from `GUEST_ROOT/etc/network/interfaces` file, like `lxc-bridge` entry. 


5. Restart networking: 
```bash
/etc/init.d/networking restart
```

You should `ping google.com` within the container. (if something goes wrong, try to restart the guest vm)


# Bridge Configuration

### Bridge with wired interface

1. Edit `/etc/network/interfaces`:

```
auto lxc-bridge
iface lxc-bridge inet dhcp
    bridge_ifaces eth0
    bridge_ports eth0
    up ifconfig eth0 up
```

2. Edit your guest vm config and remove/change any static ip addresses: 

```
# (removed) lxc.network.ipv4 = 10.0.8.8
# (removed) lxc.network.ipv4.gateway = 10.0.8.1
```

3. Use DHCP to obtain an IP address: 

```
your-guest# dhclient eth0
```

### Bridge with wireless interface 

TODO...

(see https://it-offshore.co.uk/linux/debian/60-debian-bridging-wireless-lxc-host-bridge)

# Testing

Make sure that these settings won't break some functions. After above settings, perform the 
following tests:

* Connect any wireless hotspot, verify that your guest has internet access.

* Connect a wired network, verify that your guest has internet access.

* Test connection between host and the guest: 

  * Create a server on host: `nc -l -p 6655`
  * Connect to host from guest: `echo "hello" | nc 10.0.8.1 6655`
  * See `hello` string on host console.




