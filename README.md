![image](https://cloud.githubusercontent.com/assets/6639874/25785684/93dfed2a-338f-11e7-85cb-27e17fb8dfef.png)

# LXC To The Future

Create LXC virtual machines from any BTRFS subvolume. (origin is [here](https://unix.stackexchange.com/questions/362527/how-to-boot-a-virtual-machine-from-a-regular-folder))

# Install

```console
git clone --recursive https://github.com/aktos-io/lxc-to-the-future
cd lxc-to-the-future
./snapshot-lxc

    Usage:

    	snapshot-lxc ...options


    Options

        --src /path/to/subvolume      : Subvolume source
        --name your-container-name    : Container name

        --delete your-container-name  : Delete the container
        --keep-ssh-keys               : Do not regenerate SSH keys
        --config-network              : Configure network after creation

```

# Example usage

I want to create a LXC VM from one of my snapshots:


```console
$ ./snapshot-lxc --src /path/to/snapshots/rootfs/ --name couchdb
creating the container directory: couchdb
creating a writable snapshot of given subvolume
Create a snapshot of '/path/to/snapshots/rootfs/' in '/var/lib/lxc/couchdb/rootfs'
Creating new identity for /var/lib/lxc/couchdb/rootfs
Renew hostname from cca-erik to couchdb
Adding couchdb to TARGET/etc/hosts
Re-generating ssh private keys for users
...for ceremcem
Re-generating SSH Server Keys for /var/lib/lxc/couchdb/rootfs
...generating /var/lib/lxc/couchdb/rootfs/etc/ssh/ssh_host_rsa_key
...generating /var/lib/lxc/couchdb/rootfs/etc/ssh/ssh_host_dsa_key
...generating /var/lib/lxc/couchdb/rootfs/etc/ssh/ssh_host_ecdsa_key
...generating /var/lib/lxc/couchdb/rootfs/etc/ssh/ssh_host_ed25519_key
emptying the /etc/fstab file
remove the LXC specific entry from GUEST/etc/network/interfaces file
creating the config file
done in 3 seconds...

to run the vm:

	sudo lxc-start -n couchdb

to attach the root console:

	sudo lxc-attach -n couchdb

---------------------------------------------------
                  NOTE:

* Configure network in /var/lib/lxc/couchdb/config

---------------------------------------------------

```


To make network settings for your needs as stated above, see [network-configuration](./network-configuration.md)

Start and attach the VM's console and test internet connection:

	sudo lxc-start -n mycouch
	sudo lxc-attach -n mycouch
	root@cca-erik-mycouch:# ping google.com
    PING google.com (216.58.206.206) 56(84) bytes of data.
    64 bytes from sof02s28-in-f14.1e100.net (216.58.206.206): icmp_seq=1 ttl=51 time=64.5 ms
    64 bytes from sof02s28-in-f14.1e100.net (216.58.206.206): icmp_seq=2 ttl=51 time=64.7 ms
    ^C
    --- google.com ping statistics ---
    2 packets transmitted, 2 received, 0% packet loss, time 1001ms
    rtt min/avg/max/mdev = 64.545/64.656/64.768/0.277 ms


Then make ssh:

	ssh 10.0.8.8


# Running GUI Applications

Make ssh connection with X Forwarding:

    ssh -X 10.0.8.8 freecad

# Advantages

The machine on `10.0.8.8` is the exact copy of my snapshot located at `/mnt/erik/snapshots/rootfs/rootfs.20170429T2001/`

I can install/purge any software, run a database at that time, make any configuration changes and test them, run any of these machines forever nearly with  no cost in terms of CPU, RAM (thanks to LXC), disk and time (thanks to BTRFS) resources.

# Convert VM to Real Host

If I want to use that VM as my primary OS, I just need to snapshot the `rootfs`:

    btrfs sub snap /var/lib/lxc/mytest6/rootfs /mnt/erik/rootfs_test
    cd /mnt/erik/rootfs_test/etc
    mv fstab.real fstab
    mv hostname.real hostname
    mv network/interfaces.real /network/interfaces
    reboot

Press `e` at boot time and edit the GRUB entry (or add an entry your `/boot/grub/grub.cfg`) to boot from `rootfs_test` subvolume:

    ...
    linux	/vmlinuz-4.9.0-2-amd64 root=/dev/mapper/erik-root ro  rootflags=subvol=rootfs_test
    ...

When your new system booted, check out if everything is OK.

> If something went wrong in this step, **simply reboot**, all changes will be discarded.

If everything is OK, you can make it permanent:

    cd /mnt/erik  # the device root
    mv rootfs rootfs.bak
    btrfs sub snap rootfs_test rootfs
    reboot


If everything still goes well, clean the subvolumes:

    btrfs sub delete /mnt/erik/rootfs_test
    btrfs sub delete /mnt/erik/rootfs.bak
