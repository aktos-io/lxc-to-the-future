# LXC To The Future 

Create LXC virtual machines from any BTRFS subvolume. (origin is [here](https://unix.stackexchange.com/questions/362527/how-to-boot-a-virtual-machine-from-a-regular-folder))

# Example usage

I want to create a LXC VM from one of my snapshots: 


	$ ./snapshot-lxc /mnt/erik/snapshots/rootfs/rootfs.20170429T2001/ mytest6
	This script needs root privileges.
	[sudo] password for ceremcem: 
	creating the container directory: mytest6
	creating a writable snapshot of given subvolume
	Create a snapshot of '/mnt/erik/snapshots/rootfs/rootfs.20170429T2001' in '/var/lib/lxc/mytest6/rootfs'
	emptying the /etc/fstab file
	changing hostname from cca-erik to cca-erik_mytest6
	creating the config file
	done in 1 seconds...

	to run the vm:

		sudo lxc-start -n mytest6

	to attach the root console:

		sudo lxc-attach -n mytest6



I need to attach the VM's console ([#FIXME](https://github.com/aktos-io/lxc-to-the-future/issues/2))

	sudo lxc-attach -n mytest6
	root@cca-erik_mytest6:# dhclient eth0
	root@cca-erik_mytest6:# ifconfig eth0
	eth0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
			inet 10.0.10.114  netmask 255.255.0.0  broadcast 10.0.255.255
			...


Then I can make ssh: 

	ssh 10.0.10.114


# Convert VM to Real Host

The machine on `10.0.10.114` is the exact copy of my snapshot located at `/mnt/erik/snapshots/rootfs/rootfs.20170429T2001/`

I can install/purge any software, run a database at that time, make any configuration changes and test them. If I want to use that VM as my primary OS, I just need to snapshot the `rootfs`: 

    btrfs sub snap /var/lib/lxc/mytest6/rootfs /mnt/erik/rootfs_test
    cd /mnt/erik/rootfs_test/etc
    mv fstab.real fstab
    mv hostname.real hostname

Edit your `/boot/grub/grub.cfg` (or press `e` at boot time and edit the entry) to boot from `rootfs_test` subvolume: 

    ...
    linux	/vmlinuz-4.9.0-2-amd64 root=/dev/mapper/erik-root ro  rootflags=subvol=rootfs_test
    ...
    
When your new system booted, check out if everything is OK. If so, you can make it permanent: 

    cd /mnt/erik  # the device root 
    mv rootfs rootfs.bak 
    btrfs sub snap rootfs_test rootfs 
    reboot 
    
    
> If something went wrong in this step, **simply reboot**, all changes will be - kind of - reverted. 

If everything still goes well, clean the subvolumes: 

    btrfs sub delete /mnt/erik/rootfs_test 
    btrfs sub delete /mnt/erik/rootfs.bak 
    
    
    
