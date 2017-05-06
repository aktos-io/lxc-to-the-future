# LXC To The Future 

Create LXC virtual machines from any BTRFS subvolume. (origin is [here](https://unix.stackexchange.com/questions/362527/how-to-boot-a-virtual-machine-from-a-regular-folder))

# Example usage

I want to create a LXC VM from one of my snapshots: 

```
./snapshot-lxc /mnt/erik/snapshots/rootfs/rootfs.20170429T2001/ mytest5
This script needs root privileges.
creating the container directory: mytest5
creating a writable snapshot of given subvolume
Create a snapshot of '/mnt/erik/snapshots/rootfs/rootfs.20170429T2001/' in '/var/lib/lxc/mytest5/rootfs'
emptying the /etc/fstab file
creating the config file
done in 10 seconds...

to run the vm:

        lxc-start -n mytest5

to attach the root console:

        lxc-attach -n mytest5
```

I need to attach the VM's console ([#FIXME](https://github.com/aktos-io/lxc-to-the-future/issues/2))

```
sudo lxc-attach -n mytest5
root@myhost:# dhclient eth0
root@myhost:# ifconfig eth0
eth0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 10.0.10.114  netmask 255.255.0.0  broadcast 10.0.255.255
        inet6 fe80::216:3eff:fe7e:11ac  prefixlen 64  scopeid 0x20<link>
        ether 00:16:3e:7e:11:ac  txqueuelen 1000  (Ethernet)
        RX packets 277  bytes 26005 (25.3 KiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 100  bytes 13805 (13.4 KiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

```

Then I can make ssh: 

```
ssh 10.0.10.114
```

The machine on `10.0.10.114` is the exact copy of my snapshot located at: `/mnt/erik/snapshots/rootfs/rootfs.20170429T2001/`

I can install/purge any software, run a database at that time, make any configuration changes and test them. If I want to use that VM as my primary OS, I just need to snapshot the `rootfs`: 

    btrfs sub snap /var/lib/lxc/mytest5/rootfs /mnt/erik/rootfs_test
    cd /mnt/erik/rootfs_test/etc
    mv fstab.real fstab

Edit your `/boot/grub/grub.cfg` (or press `e` at boot time and edit the entry) to boot from `rootfs_test` subvolume: 

    ...
    linux	/vmlinuz-4.9.0-2-amd64 root=/dev/mapper/erik-root ro  rootflags=subvol=rootfs_test
    ...
    
If everything goes well, you can make it permanent: 

    cd /mnt/erik  # the device root 
    mv rootfs rootfs.bak 
    btrfs sub snap rootfs_test rootfs 
    reboot 
    
If everything still goes well, clean the subvolumes: 

    btrfs sub delete /mnt/erik/rootfs_test 
    btrfs sub delete /mnt/erik/rootfs.bak 
    
    
