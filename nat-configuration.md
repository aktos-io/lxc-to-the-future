# Setup NAT configuration 

> Container will have the IP: `10.0.8.8` and its gateway will be: `10.0.8.1`

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
  
Restart networking: 

    /etc/init.d/networking restart
    
    
You should `ping google.com` within the container so far. 

# Port forwarding 

Now forward some ports from host to container: Edit again `/etc/network/interfaces` file on the host: 

        iface eth0 inet ...
            ...
            up iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 80 -j DNAT --to 10.0.8.8:80
            up iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 443 -j DNAT --to 10.0.8.8:443
            
Now you should be able to connect `10.0.8.8:443` by connecting `HOST_IP:443`. 
