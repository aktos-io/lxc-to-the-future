# Description 

There are 2 types of network connection: 

1. NAT configuration: Container will be behind a NAT firewall
2. Bridge configuration: Container will be able to directly access host network

# 1. Setup NAT Connection

> Container will have the IP: `10.0.8.8` and its gateway will be: `10.0.8.1`

1. Add the followings to the `lxc.network.` section in `/var/lib/lxc/your-container/config`: 

```
lxc.network.ipv4 = 10.0.8.8
lxc.network.ipv4.gateway = 10.0.8.1
```

2. Add `lxc-bridge` in `/etc/network/interfaces` file: 


```
auto lxc-bridge
iface lxc-bridge inet static
    bridge_ports none
    bridge_fd 0
    address 10.0.8.1
    netmask 255.255.0.0
    up /etc/network/lxc-nat-setup.sh
```

3. Create the following as `/etc/network/lxc-nat-setup.sh`:


```bash
#!/bin/sh
# This is the address we assigned to our bridge in /etc/network/interfaces
braddr=10.0.8.1

# Make sure that the IP forwarding is enabled 
echo 1 > /proc/sys/net/ipv4/ip_forward

# Cleanup the iptables (Warning: this may prevent other scripts to add their rules)
iptables -F
iptables -F -t nat

iptables -A FORWARD -i lxc-bridge -s ${braddr}/24 -m conntrack --ctstate NEW -j ACCEPT
iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A POSTROUTING -t nat -j MASQUERADE 
## Now you should be able to connect `10.0.8.8:443` by connecting `HOST_IP:443`. 

## if port forwarding is desired, uncomment the following lines:
#iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 80 -j DNAT --to 10.0.8.8:80
#iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 443 -j DNAT --to 10.0.8.8:443

```

Make sure that this script is executable:

```bash
chmod +x /etc/network/lxc-nat-bridge-up.sh
```

4. For VMs that is the clone of Host itself 

**IMPORTANT**: If you clone host machine itself (with `snapshot-lxc / my-vm` command) you should remove any LXC specific entry from `GUEST_ROOT/etc/network/interfaces` file, like `lxc-bridge` entry. 


5. Restart networking: 
```bash
/etc/init.d/networking restart
```

You should `ping google.com` within the container. (if something goes wrong, try to restart the guest vm)


# 2. Setup Bridge Connection

## Bridge with wired interface

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

## Bridge with wireless interface 

TODO...

(see https://it-offshore.co.uk/linux/debian/60-debian-bridging-wireless-lxc-host-bridge)

# Tests 

Make sure that these settings won't break some functions so you can:

* Connect any wireless hotspot, see your guest has internet access 

* Connect any wired network, see your guest has internet access 

* Test connection between host and the guest: 

  * Create a server on host: `nc -l -p 6655`
  * Connect to host from guest: `echo "hello" | nc 10.0.8.1 6655`
  * See `hello` string on host console.

  ​




