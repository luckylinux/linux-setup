# Linux Setup Tools 

I am releasing on GitHub my Install Script set of Tools which I used to install several Operating Systems, such as:
- Debian GNU/Linux
- Proxmox VE
- Ubuntu GNU/Linux
- Linux Mint GNU/Linux
- ...

I am doing a heavy refactoring of the code, so there will be a lot of breakages and things not working (yet).

Currently my tool only support 1 or 2 disks and a fixed partition layout.

Please be patient :)

# Troubleshooting
Show what **might** be keeping your Device busy so you cannot export ZFS Pool or Reformat MDADM Devices:
```
dstat -tdD /dev/sda --zfs-zil --zfs-ar --top-io --top-io-adv
```
