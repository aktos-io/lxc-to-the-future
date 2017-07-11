# Setup NAT configuration 

In the end, container will have following IP: `10.0.8.8`, Gateway: `10.0.8.1`

Change `lxc.network.` section in `/var/lib/lxc/your-container/config` as follows: 

  lxc.network.type = veth
  lxc.network.flags = up
  lxc.network.link = lxc-nat-bridge
  lxc.network.name = eth0
  lxc.network.ipv4 = 10.0.8.8
  lxc.network.ipv4.gateway = 10.0.8.1
  
  
Add `lxc-nat-bridge` in `/etc/network/interfaces` file: 

  auto lxc-nat-bridge
  iface lxc-nat-bridge inet static
      bridge_ports none
      bridge_fd 0
      address 10.0.8.1
      netmask 255.255.0.0

  iface eth0 inet ...
        ...
        up iptables -t nat -F POSTROUTING
        up iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
        
Enable IP forwarding: 

  # nano /etc/sysctl.conf
  ...
  net.ipv4.ip_forward=1    # Add this line or uncoment it
  ...
  
Your container should `ping google.com` so far. Now forward some ports from host to container: 

